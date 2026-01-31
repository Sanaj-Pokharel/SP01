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
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m,wind_gusts_10m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation,weather_code,wind_speed_10m"),
            URLQueryItem(name: "forecast_hours", value: "12")
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

        // Parse hourly forecast (next 12 hours)
        var hourlyForecast: [HourlyForecast]?
        if let hourly = response.hourly, !hourly.time.isEmpty {
            hourlyForecast = zip(hourly.time, zip(hourly.temperature2m, zip(hourly.precipitation, zip(hourly.weatherCode, hourly.windSpeed10m))))
                .map { time, data in
                    let (temp, (precip, (code, wind))) = data
                    return HourlyForecast(time: time, temperature: temp, precipitation: precip, weatherCode: code, windSpeed: wind)
                }
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
            todayRainChance: todayRainChance,
            hourlyForecast: hourlyForecast
        )
    }
    
    /// Analyze next 12 hours and determine what's needed for the day
    func analyzeDailySuggestions(from weather: WeatherInfo) -> DailySuggestions {
        guard let hourly = weather.hourlyForecast, !hourly.isEmpty else {
            // Fallback to current weather if no hourly data
            return DailySuggestions(
                needsUmbrella: weather.needsUmbrella,
                needsJacket: weather.needsJacket,
                needsSunscreen: weather.needsSunscreen,
                needsWindbreaker: weather.isWindy,
                needsWarmCoat: weather.isSnowy,
                minTemp: weather.temperature,
                maxTemp: weather.temperature,
                totalPrecipitation: weather.precipitation,
                lastUpdated: Date()
            )
        }
        
        let temps = hourly.map { $0.temperature }
        let minTemp = temps.min() ?? weather.temperature
        let maxTemp = temps.max() ?? weather.temperature
        let totalPrecip = hourly.reduce(0.0) { $0 + $1.precipitation }
        
        // Check if any hour has rain/snow
        let hasRain = hourly.contains { code in
            [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code.weatherCode)
        }
        let hasSnow = hourly.contains { code in
            [71, 73, 75, 77, 85, 86].contains(code.weatherCode)
        }
        
        // Check if it's cold (below 15°C at any point)
        let isCold = minTemp < 15
        
        // Check if it's hot and sunny (above 26°C and clear codes 0-3)
        let isHotAndSunny = maxTemp > 26 && hourly.contains { $0.weatherCode <= 3 }
        
        // Check if windy (any hour > 35 km/h)
        let isWindy = hourly.contains { $0.windSpeed > 35 }
        
        return DailySuggestions(
            needsUmbrella: hasRain || totalPrecip > 0.5,
            needsJacket: isCold,
            needsSunscreen: isHotAndSunny,
            needsWindbreaker: isWindy,
            needsWarmCoat: hasSnow,
            minTemp: minTemp,
            maxTemp: maxTemp,
            totalPrecipitation: totalPrecip,
            lastUpdated: Date()
        )
    }
}
