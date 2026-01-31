//
//  Weather.swift
//  SP01
//

import Foundation

enum WeatherError: LocalizedError {
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .serverError(let code):
            return "Weather service returned error \(code). Try again in a moment."
        }
    }
}

// Open-Meteo API response (current + hourly + daily)
struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentWeather?
    let hourly: HourlyWeather?
    let daily: DailyWeather?
}

struct CurrentWeather: Codable {
    let time: String
    let temperature2m: Double
    let relativeHumidity2m: Int?
    let precipitation: Double?
    let weatherCode: Int
    let windSpeed10m: Double?
    let windGusts10m: Double?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
        case windGusts10m = "wind_gusts_10m"
    }
}

struct HourlyWeather: Codable {
    let time: [String]
    let temperature2m: [Double]
    let precipitation: [Double]
    let weatherCode: [Int]
    let windSpeed10m: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
    }
}

struct DailyWeather: Codable {
    let time: [String]
    let precipitationSum: [Double?]?
    let weatherCodeMax: [Int?]?
    let temperature2mMax: [Double?]?
    let temperature2mMin: [Double?]?
    let precipitationProbabilityMax: [Int?]?

    enum CodingKeys: String, CodingKey {
        case time
        case precipitationSum = "precipitation_sum"
        case weatherCodeMax = "weather_code_max"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}

// Parsed weather for the UI
struct WeatherInfo: Codable {
    let temperature: Double
    let humidity: Int?
    let precipitation: Double
    let weatherCode: Int
    let windSpeed: Double
    let windGusts: Double?
    let todayHigh: Double?
    let todayLow: Double?
    let todayRainChance: Int?
    let hourlyForecast: [HourlyForecast]?

    /// Open-Meteo WMO weather codes: rain 61–67, 80–82; snow 71–77, 85–86; drizzle 51–57; thunder 95–99
    var isRainy: Bool {
        switch weatherCode {
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82:
            return true
        default:
            return false
        }
    }

    var isSnowy: Bool {
        switch weatherCode {
        case 71, 73, 75, 77, 85, 86:
            return true
        default:
            return false
        }
    }

    var isStormy: Bool {
        (95...99).contains(weatherCode)
    }

    var needsUmbrella: Bool { isRainy || precipitation > 0 }
    var needsJacket: Bool { temperature < 15 }
    var needsSunscreen: Bool { temperature > 26 && weatherCode <= 3 }
    var isWindy: Bool { (windGusts ?? windSpeed) > 35 }
}

// Single hour in the forecast
struct HourlyForecast: Codable {
    let time: String
    let temperature: Double
    let precipitation: Double
    let weatherCode: Int
    let windSpeed: Double
}

// Analysis of next 12 hours for widget
struct DailySuggestions: Codable {
    let needsUmbrella: Bool
    let needsJacket: Bool
    let needsSunscreen: Bool
    let needsWindbreaker: Bool
    let needsWarmCoat: Bool
    let minTemp: Double
    let maxTemp: Double
    let totalPrecipitation: Double
    let lastUpdated: Date
    
    var items: [String] {
        var result: [String] = []
        if needsUmbrella { result.append("Umbrella") }
        if needsJacket { result.append("Jacket") }
        if needsSunscreen { result.append("Sunscreen") }
        if needsWindbreaker { result.append("Windbreaker") }
        if needsWarmCoat { result.append("Warm coat") }
        if result.isEmpty { result.append("Looking good") }
        return result
    }
}
