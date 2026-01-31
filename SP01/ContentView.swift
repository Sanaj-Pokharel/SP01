//
//  ContentView.swift
//  SP01
//

import CoreLocation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    @State private var weather: WeatherInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasRequestedLocation = false

    private let weatherService = WeatherService()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading weather…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "cloud.sun.rain")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        if locationManager.authorizationStatus == .denied {
                            Text("Enable location in Settings to get local weather.")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Location may take a few seconds. Waiting for GPS…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Try again") {
                                errorMessage = nil
                                locationManager.requestLocation()
                                Task {
                                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                                    await fetchWeatherIfPossible()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let w = weather {
                    weatherContent(weather: w)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.tint)
                        Text("Allow location to see your weather and get umbrella, jacket, and other reminders.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        Button("Use my location") {
                            requestLocationAndFetch()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("SP01 Weather")
            .toolbar {
                if weather != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await fetchWeatherIfPossible() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .task {
            await notificationManager.requestPermission()
        }
        .onChange(of: locationManager.lastLocation) { _, newLocation in
            if newLocation != nil, hasRequestedLocation, weather == nil, !isLoading {
                Task { await fetchWeatherIfPossible() }
            }
        }
    }

    private func requestLocationAndFetch() {
        hasRequestedLocation = true
        errorMessage = nil
        locationManager.requestPermission()
        locationManager.requestLocation()
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await fetchWeatherIfPossible()
        }
    }

    private func fetchWeatherIfPossible() async {
        guard let coords = locationManager.coordinates else {
            if hasRequestedLocation && locationManager.authorizationStatus == .denied {
                errorMessage = "Location was denied. Enable it in Settings to get local weather."
            } else if hasRequestedLocation {
                errorMessage = "Could not get your location. Try again or check Settings."
            }
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            weather = try await weatherService.fetchWeather(latitude: coords.lat, longitude: coords.lon)
            
            // Analyze and save suggestions for widget
            if let w = weather {
                let suggestions = weatherService.analyzeDailySuggestions(from: w)
                SharedDataManager.shared.saveDailySuggestions(suggestions)
                
                // Refresh widget timeline
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            }
        } catch let err as WeatherError {
            errorMessage = err.localizedDescription
        } catch {
            errorMessage = "Could not load weather. Check your connection and try again."
        }
    }

    @ViewBuilder
    private func weatherContent(weather w: WeatherInfo) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Current conditions
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Int(w.temperature))°")
                            .font(.system(size: 56, weight: .light))
                        if let high = w.todayHigh {
                            Text("H \(Int(high))°")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        if let low = w.todayLow {
                            Text("L \(Int(low))°")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let hum = w.humidity {
                        Text("Humidity \(hum)%")
                            .foregroundStyle(.secondary)
                    }
                    Text("Wind \(Int(w.windSpeed)) km/h\(w.windGusts.map { " (gusts \(Int($0)))" } ?? "")")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Suggestions (umbrella, jacket, etc.)
                VStack(alignment: .leading, spacing: 12) {
                    Text("What to bring")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        if w.needsUmbrella {
                            SuggestionChip(icon: "umbrella.fill", text: "Umbrella")
                        }
                        if w.needsJacket {
                            SuggestionChip(icon: "cloud.fill", text: "Jacket")
                        }
                        if w.needsSunscreen {
                            SuggestionChip(icon: "sun.max.fill", text: "Sunscreen")
                        }
                        if w.isWindy {
                            SuggestionChip(icon: "wind", text: "Windbreaker")
                        }
                        if w.isSnowy {
                            SuggestionChip(icon: "snowflake", text: "Warm coat")
                        }
                        if w.isStormy {
                            SuggestionChip(icon: "cloud.bolt.fill", text: "Stay safe")
                        }
                        if !w.needsUmbrella && !w.needsJacket && !w.needsSunscreen && !w.isWindy && !w.isSnowy && !w.isStormy {
                            SuggestionChip(icon: "checkmark.circle.fill", text: "Looking good")
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Notify me button
                if notificationManager.isAuthorized {
                    Button {
                        notificationManager.scheduleWeatherSuggestion(weather: w)
                    } label: {
                        Label("Send me a reminder now", systemImage: "bell.badge")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .refreshable {
            await fetchWeatherIfPossible()
        }
    }
}

struct SuggestionChip: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.tint.opacity(0.2), in: Capsule())
    }
}

#Preview {
    ContentView()
}
