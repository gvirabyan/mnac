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
    // Required for flutter_local_notifications to present alerts while the app
    // is in the foreground on iOS.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    if let controller = window?.rootViewController as? FlutterViewController {
      StoryShareChannel.register(messenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
