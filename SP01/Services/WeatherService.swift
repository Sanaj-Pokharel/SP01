//
//  WeatherService.swift
//  SP01
//

import Foundation

/// Fetches weather from Open-Meteo (free, no API key).
/// Docs: https://open-meteo.com/en/docs
final class WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private let session: URLSession = .shared

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherInfo {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m,wind_gusts_10m")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue("SP01/1.0 (iOS; Weather)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard http.statusCode == 200 else {
            throw WeatherError.serverError(statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
        return mapToWeatherInfo(decoded)
    }

    private func mapToWeatherInfo(_ response: WeatherResponse) -> WeatherInfo {
        let cur = response.current
        let temp = cur?.temperature2m ?? 0
        let code = cur?.weatherCode ?? 0
        let precip = cur?.precipitation ?? 0
        let wind = cur?.windSpeed10m ?? 0
        let gusts = cur?.windGusts10m

        var todayHigh: Double?
        var todayLow: Double?
        var todayRainChance: Int?
        if let daily = response.daily, !daily.time.isEmpty {
            todayHigh = daily.temperature2mMax?.first.flatMap { $0 }
            todayLow = daily.temperature2mMin?.first.flatMap { $0 }
            todayRainChance = daily.precipitationProbabilityMax?.first.flatMap { $0 }
        }

        return WeatherInfo(
            temperature: temp,
            humidity: cur?.relativeHumidity2m,
            precipitation: precip,
            weatherCode: code,
            windSpeed: wind,
            windGusts: gusts,
            todayHigh: todayHigh,
            todayLow: todayLow,
            todayRainChance: todayRainChance
        )
    }
}
