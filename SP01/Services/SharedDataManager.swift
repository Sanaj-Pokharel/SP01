//
//  SharedDataManager.swift
//  SP01
//

import Foundation

/// Manages data sharing between the main app and the widget using App Groups
final class SharedDataManager {
    static let shared = SharedDataManager()
    private let appGroupID = "group.com.sanaj.SP01"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    func saveDailySuggestions(_ suggestions: DailySuggestions) {
        guard let defaults = sharedDefaults else { return }
        if let encoded = try? JSONEncoder().encode(suggestions) {
            defaults.set(encoded, forKey: "dailySuggestions")
        }
    }
    
    func loadDailySuggestions() -> DailySuggestions? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "dailySuggestions"),
              let suggestions = try? JSONDecoder().decode(DailySuggestions.self, from: data) else {
            return nil
        }
        return suggestions
    }
}
