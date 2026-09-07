import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    PushDiagnostics.observeRegistration(with: self)
    // Required for flutter_local_notifications to present alerts while the app
    // is in the foreground on iOS.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    if let controller = window?.rootViewController as? FlutterViewController {
      StoryShareChannel.register(messenger: controller.binaryMessenger)
      DiagnosticsChannel.register(messenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// What the app itself can see about its APNs registration.
///
/// Everything here answers a question the Dart side cannot: whether iOS ever
/// called back at all, what it said when it refused, and which APNs
/// environment the signed build is actually entitled to — the last one read
/// from the embedded provisioning profile rather than the entitlements file,
/// so it reflects what the profile granted rather than what the source asked
/// for. A mismatch between that and the token type Firebase registers is the
/// usual reason a push that works in one build never arrives in another.
enum PushDiagnostics {
  private static var deviceTokenLength: Int?
  private static var failure: String?

  /// Listens for the APNs callbacks by joining the plugin delegate chain
  /// rather than overriding them on `AppDelegate`: `FlutterAppDelegate`
  /// implements both but declares neither in its header, so a Swift subclass
  /// has nothing to override. Registering an observer is the supported route
  /// and leaves every other plugin's copy of the callback untouched.
  static func observeRegistration(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: observerName) else { return }
    registrar.addApplicationDelegate(observer)
  }

  private static let observerName = "PushDiagnosticsObserver"
  private static let observer = PushDiagnosticsObserver()

  fileprivate static func recordToken(_ token: Data) {
    deviceTokenLength = token.count
    failure = nil
  }

  fileprivate static func recordFailure(_ error: Error) {
    let ns = error as NSError
    failure = "\(ns.domain) \(ns.code): \(ns.localizedDescription)"
  }

  static func report() -> String {
    var lines: [String] = []

    if let length = deviceTokenLength {
      lines.append("apns callback: token received (\(length) bytes)")
    } else if let failure {
      lines.append("apns callback: FAILED (\(failure))")
    } else {
      lines.append("apns callback: never fired")
    }

    let registered = UIApplication.shared.isRegisteredForRemoteNotifications
    lines.append("registered for remote: \(registered)")
    lines.append("profile aps-environment: \(provisionedAPSEnvironment() ?? "none")")

    #if DEBUG
      lines.append("build: debug (Firebase registers a sandbox APNs token)")
    #else
      lines.append("build: release (Firebase registers a production APNs token)")
    #endif

    return lines.joined(separator: "\n")
  }

  /// The APNs environment the embedded profile grants, or nil when it
  /// carries no push entitlement — exactly the case where registration fails
  /// and no token ever arrives.
  private static func provisionedAPSEnvironment() -> String? {
    ProvisioningProfile.string(
      forAnyOf: ["aps-environment", "com.apple.developer.aps-environment"])
  }
}

/// The provisioning profile embedded in this build.
///
/// A CMS-signed blob wrapping a plist; scanning it as text avoids pulling in
/// a decoder to read a couple of keys. Absent on the simulator, where neither
/// push nor App Group sharing behaves like it does on a device anyway.
enum ProvisioningProfile {
  private static let text: String? = {
    guard
      let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
      let data = FileManager.default.contents(atPath: path)
    else {
      return nil
    }
    return String(data: data, encoding: .isoLatin1)
  }()

  /// The `<string>` following whichever of `keys` appears first.
  ///
  /// Several entitlements exist under two spellings — bare, and prefixed with
  /// `com.apple.developer.` — and reading only one reports an entitled build
  /// as having none, which sends you off fixing signing that was never broken.
  static func string(forAnyOf keys: [String]) -> String? {
    guard let text else { return nil }
    for key in keys {
      guard
        let keyRange = text.range(of: "<key>\(key)</key>"),
        let open = text.range(of: "<string>", range: keyRange.upperBound..<text.endIndex),
        let close = text.range(of: "</string>", range: open.upperBound..<text.endIndex)
      else {
        continue
      }
      return String(text[open.upperBound..<close.lowerBound])
    }
    return nil
  }

  /// Every `<string>` in the `<array>` following `key`.
  static func strings(forKey key: String) -> [String] {
    guard
      let text,
      let keyRange = text.range(of: "<key>\(key)</key>"),
      let open = text.range(of: "<array>", range: keyRange.upperBound..<text.endIndex),
      let close = text.range(of: "</array>", range: open.upperBound..<text.endIndex)
    else {
      return []
    }

    var values: [String] = []
    var cursor = open.upperBound
    while
      let itemOpen = text.range(of: "<string>", range: cursor..<close.lowerBound),
      let itemClose = text.range(of: "</string>", range: itemOpen.upperBound..<close.lowerBound)
    {
      values.append(String(text[itemOpen.upperBound..<itemClose.lowerBound]))
      cursor = itemClose.upperBound
    }
    return values
  }
}

/// Records what APNs told the app, for [PushDiagnostics].
final class PushDiagnosticsObserver: NSObject, FlutterPlugin {
  // Never invoked: the observer is registered by hand, not by the generated
  // registrant. Required by `FlutterPlugin`, which `addApplicationDelegate`
  // takes.
  static func register(with registrar: FlutterPluginRegistrar) {}

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    PushDiagnostics.recordToken(deviceToken)
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    PushDiagnostics.recordFailure(error)
  }
}

/// Why the home-screen widget shows its placeholder instead of a countdown.
///
/// The app and the widget extension are separate processes sharing nothing
/// but the App Group container, and every way that sharing can break looks
/// identical from the home screen — an empty widget. So the report separates
/// them: whether the group is granted at all, whether the profile actually
/// carries it, and what the extension would read back if it ran right now.
///
/// Read from the app, not the extension: a widget cannot report on itself,
/// and both processes see the same shared store when the group works. If the
/// group is missing they see different ones, which is precisely the fault
/// being looked for.
enum WidgetDiagnostics {
  private static let appGroupId = "group.com.virabyan.mnac.widget"
  private static let dataKey = "widget_soldiers"
  private static let indexKey = "widget_soldier_index"

  static func report() -> String {
    var lines: [String] = []

    // nil means the entitlement is not in force, whatever the .entitlements
    // file in the source tree says. This is the check that matters: without a
    // container the two processes are simply not sharing anything.
    let container = FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    lines.append("app group container: \(container == nil ? "UNAVAILABLE" : "available")")

    let groups = ProvisioningProfile.strings(forKey: "com.apple.security.application-groups")
    lines.append(
      "profile app groups: \(groups.isEmpty ? "none" : groups.joined(separator: ", "))")

    let defaults = UserDefaults(suiteName: appGroupId)
    if let raw = defaults?.string(forKey: dataKey) {
      let items = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [[String: String]]
      let parsed = items.map { "\($0.count) soldiers" } ?? "UNREADABLE"
      lines.append("\(dataKey): \(raw.count) chars, \(parsed)")
    } else {
      lines.append("\(dataKey): MISSING")
    }

    lines.append("\(indexKey): \(defaults?.integer(forKey: indexKey) ?? 0)")

    return lines.joined(separator: "\n")
  }
}

enum DiagnosticsChannel {
  static let name = "com.virabyan.mnac/diagnostics"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "push":
        result(PushDiagnostics.report())
      case "widget":
        result(WidgetDiagnostics.report())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Shares a rendered story image straight into the Instagram Stories composer,
/// skipping the system share sheet.
///
/// iOS has no intent equivalent: Instagram reads the image off the general
/// pasteboard under its own key, then `instagram-stories://share` opens the
/// composer. Since January 2023 Meta requires a Facebook App ID in
/// `source_application`, otherwise Instagram opens and reports that sharing is
/// unsupported.
///
/// Lives in this file rather than its own so it is compiled without touching
/// the Xcode project file.
enum StoryShareChannel {
  static let name = "com.virabyan.mnac/story_share"

  private static let backgroundImageKey = "com.instagram.sharedSticker.backgroundImage"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isInstagramInstalled":
        result(canOpenStories(appId: nil))
      case "shareToInstagramStory":
        share(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func storiesURL(appId: String?) -> URL? {
    guard let appId, !appId.isEmpty else {
      return URL(string: "instagram-stories://share")
    }
    return URL(string: "instagram-stories://share?source_application=\(appId)")
  }

  private static func canOpenStories(appId: String?) -> Bool {
    guard let url = storiesURL(appId: appId) else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private static func share(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let imagePath = args["imagePath"] as? String,
      let appId = args["appId"] as? String,
      !imagePath.isEmpty, !appId.isEmpty
    else {
      result(FlutterError(code: "bad_args", message: "imagePath and appId are required", details: nil))
      return
    }

    guard
      let data = FileManager.default.contents(atPath: imagePath),
      let image = UIImage(data: data)
    else {
      result(FlutterError(code: "missing_file", message: "Story image not found: \(imagePath)", details: nil))
      return
    }

    guard let url = storiesURL(appId: appId), UIApplication.shared.canOpenURL(url) else {
      result(false)
      return
    }

    // Instagram reads the pasteboard right after being opened, so the items
    // only need to outlive the hand-off.
    let items: [[String: Any]] = [[backgroundImageKey: image]]
    UIPasteboard.general.setItems(
      items,
      options: [.expirationDate: Date().addingTimeInterval(300)]
    )

    UIApplication.shared.open(url, options: [:]) { opened in
      result(opened)
    }
  }
}
