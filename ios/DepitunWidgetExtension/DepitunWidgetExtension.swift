import SwiftUI
import WidgetKit

/// Mirrors `HomeWidgetService` / `DepitunWidgetProvider.kt` on Android: shows
/// the first soldier's countdown, written by the app into the shared App
/// Group container as a JSON blob under the key below.
private let appGroupId = "group.com.virabyan.mnac.widget"
private let widgetDataKey = "widget_soldiers"

struct DepitunEntry: TimelineEntry {
  let date: Date
  let title: String
  let days: String
  let percent: String
  let discharge: String
  let photoPath: String?
}

/// Reads the first soldier's data written by the app. Only the first soldier
/// is shown — the extension's sandbox can't page through soldiers the way
/// the Android widget's "next" button does.
private func loadEntry() -> DepitunEntry {
  let placeholder = DepitunEntry(
    date: Date(), title: "Մնաց", days: "—", percent: "", discharge: "", photoPath: nil)

  guard
    let raw = UserDefaults(suiteName: appGroupId)?.string(forKey: widgetDataKey),
    let data = raw.data(using: .utf8),
    let items = try? JSONSerialization.jsonObject(with: data) as? [[String: String]],
    let first = items.first
  else {
    return placeholder
  }

  let photoPath = first["photoPath"]
  return DepitunEntry(
    date: Date(),
    title: first["title"] ?? placeholder.title,
    days: first["days"] ?? placeholder.days,
    percent: first["percent"] ?? "",
    discharge: first["discharge"] ?? "",
    photoPath: (photoPath?.isEmpty ?? true) ? nil : photoPath
  )
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> DepitunEntry {
    DepitunEntry(date: Date(), title: "Մնաց", days: "—", percent: "", discharge: "", photoPath: nil)
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
  let kind: String = "DepitunWidgetExtension"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      DepitunWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Դեպի Տուն")
    .description("Մնացած օրերը մինչև զորացրում։")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
