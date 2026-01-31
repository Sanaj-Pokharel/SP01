//
//  SP01Widget.swift
//  SP01Widget
//
//  Created by Sanaj Pokharel on 31/1/2026.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), suggestions: DailySuggestions(
            needsUmbrella: false,
            needsJacket: false,
            needsSunscreen: false,
            needsWindbreaker: false,
            needsWarmCoat: false,
            minTemp: 20,
            maxTemp: 25,
            totalPrecipitation: 0,
            lastUpdated: Date()
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), suggestions: loadSuggestions())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let suggestions = loadSuggestions()
        
        // Create entry for now
        let entry = SimpleEntry(date: currentDate, suggestions: suggestions)
        
        // Schedule next update for 7 AM tomorrow
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = 7
        components.minute = 0
        
        var nextUpdate = calendar.date(from: components) ?? currentDate
        if nextUpdate <= currentDate {
            // If 7 AM today has passed, schedule for 7 AM tomorrow
            nextUpdate = calendar.date(byAdding: .day, value: 1, to: nextUpdate) ?? currentDate
        }
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadSuggestions() -> DailySuggestions {
        // Load from shared UserDefaults (App Group)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.sanaj.SP01"),
           let data = sharedDefaults.data(forKey: "dailySuggestions"),
           let suggestions = try? JSONDecoder().decode(DailySuggestions.self, from: data) {
            return suggestions
        }
        
        // Default fallback
        return DailySuggestions(
            needsUmbrella: false,
            needsJacket: false,
            needsSunscreen: false,
            needsWindbreaker: false,
            needsWarmCoat: false,
            minTemp: 0,
            maxTemp: 0,
            totalPrecipitation: 0,
            lastUpdated: Date()
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let suggestions: DailySuggestions
}

struct SP01WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("What to bring")
                    .font(.headline)
                Spacer()
            }
            
            if entry.suggestions.items.isEmpty {
                Text("Looking good")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.suggestions.items, id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: iconFor(item: item))
                                .font(.caption)
                                .foregroundStyle(.tint)
                            Text(item)
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Text("\(Int(entry.suggestions.minTemp))° – \(Int(entry.suggestions.maxTemp))°")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.suggestions.lastUpdated, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
    
    private func iconFor(item: String) -> String {
        switch item {
        case "Umbrella": return "umbrella.fill"
        case "Jacket": return "cloud.fill"
        case "Sunscreen": return "sun.max.fill"
        case "Windbreaker": return "wind"
        case "Warm coat": return "snowflake"
        default: return "checkmark.circle.fill"
        }
    }
}

struct SP01Widget: Widget {
    let kind: String = "SP01Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SP01WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("SP01 Weather")
        .description("See what you need for the day based on the next 12 hours of weather.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    SP01Widget()
} timeline: {
    SimpleEntry(date: .now, suggestions: DailySuggestions(
        needsUmbrella: true,
        needsJacket: true,
        needsSunscreen: false,
        needsWindbreaker: false,
        needsWarmCoat: false,
        minTemp: 12,
        maxTemp: 18,
        totalPrecipitation: 2.5,
        lastUpdated: Date()
    ))
}
