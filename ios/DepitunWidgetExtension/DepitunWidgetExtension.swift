import AppIntents
import SwiftUI
import WidgetKit

/// Mirrors `HomeWidgetService` / `DepitunWidgetProvider.kt` on Android: the
/// app writes every soldier as a JSON blob under `widgetDataKey`. Which one
/// is shown is tracked by `widgetIndexKey`, advanced by `NextSoldierIntent`
/// (iOS 17+) — the closest counterpart to Android's "next" button, which
/// pages via a broadcast receiver instead.
private let appGroupId = "group.com.virabyan.mnac.widget"
private let widgetDataKey = "widget_soldiers"
private let widgetIndexKey = "widget_soldier_index"
private let widgetKind = "DepitunWidgetExtension"

struct DepitunEntry: TimelineEntry {
  let date: Date
  let title: String
  let days: String
  let percent: String
  let discharge: String
  let photoPath: String?
  let soldierCount: Int
}

private func loadSoldiers() -> [[String: String]] {
  guard
    let raw = UserDefaults(suiteName: appGroupId)?.string(forKey: widgetDataKey),
    let data = raw.data(using: .utf8),
    let items = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
  else {
    return []
  }
  return items
}

/// Reads the soldier at the currently-selected index (clamped in case the
/// list shrank since the index was last advanced).
private func loadEntry() -> DepitunEntry {
  let placeholder = DepitunEntry(
    date: Date(), title: "Մնաց", days: "—", percent: "", discharge: "", photoPath: nil,
    soldierCount: 0)

  let items = loadSoldiers()
  guard !items.isEmpty else { return placeholder }

  let defaults = UserDefaults(suiteName: appGroupId)
  var index = defaults?.integer(forKey: widgetIndexKey) ?? 0
  if index < 0 || index >= items.count {
    index = 0
    defaults?.set(0, forKey: widgetIndexKey)
  }

  let soldier = items[index]
  let photoPath = soldier["photoPath"]
  return DepitunEntry(
    date: Date(),
    title: soldier["title"] ?? placeholder.title,
    days: soldier["days"] ?? placeholder.days,
    percent: soldier["percent"] ?? "",
    discharge: soldier["discharge"] ?? "",
    photoPath: (photoPath?.isEmpty ?? true) ? nil : photoPath,
    soldierCount: items.count
  )
}

/// Advances the shown soldier, wrapping around. Runs in-process in the
/// widget extension (no app launch), like Android's broadcast receiver.
/// Interactive widget buttons need iOS 17+; below that the button that
/// would invoke this simply isn't shown (see `nextButton` in the view).
@available(iOS 17.0, *)
struct NextSoldierIntent: AppIntent {
  static var title: LocalizedStringResource = "Հաջորդ զինվոր"
  static var description = IntentDescription("Ցուցադրել հաջորդ զինվորի հաշվիչը վիջեթում։")

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroupId)
    let count = loadSoldiers().count
    if count > 1 {
      let current = defaults?.integer(forKey: widgetIndexKey) ?? 0
      defaults?.set((current + 1) % count, forKey: widgetIndexKey)
    }
    WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    return .result()
  }
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> DepitunEntry {
    DepitunEntry(
      date: Date(), title: "Մնաց", days: "—", percent: "", discharge: "", photoPath: nil,
      soldierCount: 0)
  }

  func getSnapshot(in context: Context, completion: @escaping (DepitunEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DepitunEntry>) -> Void) {
    let entry = loadEntry()
    // Same ~30 min cadence as the Android provider's updatePeriodMillis.
    let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
      ?? Date().addingTimeInterval(1800)
    completion(Timeline(entries: [entry], policy: .after(refresh)))
  }
}

struct DepitunWidgetEntryView: View {
  var entry: Provider.Entry

  private static let cream = Color(red: 0.957, green: 0.925, blue: 0.882) // #F4ECE1
  private static let ink = Color(red: 0.118, green: 0.106, blue: 0.086) // #1E1B16
  private static let muted = Color(red: 0.541, green: 0.510, blue: 0.463) // #8A8276
  private static let accent = Color(red: 0.949, green: 0.663, blue: 0.0) // #F2A900

  private var hasPhoto: Bool { entry.photoPath != nil }

  var body: some View {
    ZStack(alignment: .topLeading) {
      background
      content
        .padding(16)
      if entry.soldierCount > 1 {
        nextButton
      }
    }
  }

  /// Bottom-trailing "next soldier" button, mirroring the Android widget's
  /// paging control. Hidden below iOS 17 (no interactive widget support) and
  /// when there's only one soldier (mirrors Android's visibility rule).
  @ViewBuilder
  private var nextButton: some View {
    if #available(iOS 17.0, *) {
      VStack {
        Spacer()
        HStack {
          Spacer()
          Button(intent: NextSoldierIntent()) {
            Image(systemName: "chevron.right.circle.fill")
              .font(.system(size: 20))
              .foregroundColor(hasPhoto ? .white : Self.ink)
              .opacity(0.85)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(10)
    }
  }

  @ViewBuilder
  private var background: some View {
    if let path = entry.photoPath, let uiImage = UIImage(contentsOfFile: path) {
      ZStack {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
        LinearGradient(
          colors: [Color.black.opacity(0.15), Color.black.opacity(0.55)],
          startPoint: .top,
          endPoint: .bottom
        )
      }
    } else {
      Self.cream
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(entry.title)
        .font(.system(size: 12))
        .foregroundColor(hasPhoto ? .white.opacity(0.85) : Self.muted)
        .lineLimit(1)

      HStack(alignment: .lastTextBaseline, spacing: 4) {
        Text(entry.days)
          .font(.system(size: 34, weight: .bold))
          .foregroundColor(Self.accent)
        Text("օր")
          .font(.system(size: 14))
          .foregroundColor(hasPhoto ? .white : Self.ink)
      }

      Text("մինչև տուն")
        .font(.system(size: 12))
        .foregroundColor(hasPhoto ? .white : Self.ink)

      if !entry.percent.isEmpty {
        Text(entry.percent)
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(hasPhoto ? .white : Self.ink)
          .lineLimit(1)
          .padding(.top, 4)
      }

      if !entry.discharge.isEmpty {
        Text(entry.discharge)
          .font(.system(size: 10))
          .foregroundColor(hasPhoto ? .white.opacity(0.85) : Self.muted)
          .lineLimit(1)
          .padding(.top, 2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

@main
struct DepitunWidget: Widget {
  let kind: String = widgetKind

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      DepitunWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Դեպի Տուն")
    .description("Մնացած օրերը մինչև զորացրում։")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
