//
//  NotificationManager.swift
//  SP01
//

import Combine
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published var isAuthorized = false

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        isAuthorized = granted
    }

    func scheduleWeatherSuggestion(weather: WeatherInfo) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        var suggestions: [String] = []
        if weather.needsUmbrella { suggestions.append("Take an umbrella") }
        if weather.needsJacket { suggestions.append("Wear a jacket") }
        if weather.needsSunscreen { suggestions.append("Use sunscreen") }
        if weather.isWindy { suggestions.append("Bring a windbreaker") }
        if weather.isSnowy { suggestions.append("Dress warm — snow expected") }
        if weather.isStormy { suggestions.append("Thunderstorms possible — stay safe") }

        if suggestions.isEmpty {
            content.title = "Weather update"
            content.body = "\(Int(weather.temperature))°C and looking fine. Have a good one!"
        } else {
            content.title = "Heads up"
            content.body = suggestions.joined(separator: ". ")
        }

        let request = UNNotificationRequest(
            identifier: "weather-suggestion-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}
