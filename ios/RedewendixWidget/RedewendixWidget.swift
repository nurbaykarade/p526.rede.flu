import SwiftUI
import WidgetKit

/// Startbildschirm-Widget mit der Redewendung des Tages.
///
/// Die App legt in der App Group unter "days" die Redewendungen der nächsten
/// Tage ab ({"2026-09-27": {"id": 1, "text": "…", "meaning": "…"}, …}). Daraus
/// baut das Widget eine Zeitleiste mit einem Eintrag pro Tag.

private let appGroupId = "group.bq.p526.rede"

struct IdiomEntry: TimelineEntry {
  let date: Date
  let id: Int?
  let text: String
  let meaning: String

  static let fallback = IdiomEntry(
    date: Date(), id: nil, text: "Redewendix",
    meaning: "Öffne die App für neue Redewendungen.")

  static let sample = IdiomEntry(
    date: Date(), id: nil, text: "„Tomaten auf den Augen haben“",
    meaning: "Etwas Offensichtliches nicht sehen.")
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> IdiomEntry { .sample }

  func getSnapshot(in context: Context, completion: @escaping (IdiomEntry) -> Void) {
    completion(entry(for: Date(), days: loadDays()) ?? .sample)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<IdiomEntry>) -> Void) {
    let calendar = Calendar.current
    let days = loadDays()
    let today = calendar.startOfDay(for: Date())
    var entries: [IdiomEntry] = []
    for offset in 0..<31 {
      guard let day = calendar.date(byAdding: .day, value: offset, to: today),
        let e = entry(for: offset == 0 ? Date() : day, days: days)
      else { continue }
      entries.append(e)
    }
    if entries.isEmpty { entries = [.fallback] }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func loadDays() -> [String: [String: Any]] {
    guard let json = UserDefaults(suiteName: appGroupId)?.string(forKey: "days"),
      let data = json.data(using: .utf8),
      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
    else { return [:] }
    return obj
  }

  private func entry(for date: Date, days: [String: [String: Any]]) -> IdiomEntry? {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    guard let day = days[formatter.string(from: date)],
      let text = day["text"] as? String
    else { return nil }
    return IdiomEntry(
      date: date, id: day["id"] as? Int, text: "„\(text)“",
      meaning: day["meaning"] as? String ?? "")
  }
}

struct RedewendixWidgetView: View {
  @Environment(\.widgetFamily) var family
  var entry: IdiomEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Redewendung des Tages")
        .font(.caption2)
        .foregroundColor(Color("WidgetLabel"))
      Text(entry.text)
        .font(family == .systemSmall ? .subheadline : .headline)
        .fontWeight(.bold)
        .foregroundColor(Color("WidgetText"))
        .lineLimit(family == .systemSmall ? 4 : 3)
        .minimumScaleFactor(0.8)
      if family != .systemSmall {
        Text(entry.meaning)
          .font(.subheadline)
          .foregroundColor(Color("WidgetLabel"))
          .lineLimit(3)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(URL(string: "redewendix://idiom/\(entry.id ?? 0)?homeWidget"))
    .widgetBackground(Color("WidgetBackground"))
  }
}

extension View {
  @ViewBuilder
  func widgetBackground(_ color: Color) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      padding().background(color)
    }
  }
}

@main
struct RedewendixWidget: Widget {
  let kind = "RedewendixWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      RedewendixWidgetView(entry: entry)
    }
    .configurationDisplayName("Redewendung des Tages")
    .description("Jeden Tag eine deutsche Redewendung auf dem Startbildschirm.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
