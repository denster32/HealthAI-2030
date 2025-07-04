import Foundation
import Combine

// MARK: - Environmental API Client Protocol

/// Defines the interface for fetching environmental data from an external API.
protocol EnvironmentalAPIService {
    func fetchCurrentEnvironmentalData(latitude: Double, longitude: Double) -> AnyPublisher<EnvironmentalData, Error>
    func fetchHistoricalEnvironmentalData(latitude: Double, longitude: Double, date: Date) -> AnyPublisher<EnvironmentalData, Error>
    // Add more methods for forecast, specific pollutants, etc. as needed
}

// MARK: - Concrete API Client Implementation

/// A concrete implementation of EnvironmentalAPIService using a hypothetical external API.
class EnvironmentalAPIClient: EnvironmentalAPIService {

    private let baseURL: URL
    private let apiKey: String // In a real app, this would be securely managed (e.g., environment variable, secrets manager)

    enum APIError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case apiError(String) // For errors returned by the API itself

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL."
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .decodingError(let error): return "Data decoding error: \(error.localizedDescription)"
            case .apiError(let message): return "API error: \(message)"
            }
        }
    }

    init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    /// Fetches current environmental data.
    func fetchCurrentEnvironmentalData(latitude: Double, longitude: Double) -> AnyPublisher<EnvironmentalData, Error> {
        // Construct URL for current data (example for a hypothetical API)
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent("current"), resolvingAgainstBaseURL: true) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: "\(latitude)"),
            URLQueryItem(name: "lon", value: "\(longitude)"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]

        guard let url = urlComponents.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let errorString = String(data: data, encoding: .utf8) ?? "Unknown API Error"
                    throw APIError.apiError("Server responded with status \( (response as? HTTPURLResponse)?.statusCode ?? -1): \(errorString)")
                }
                return data
            }
            .decode(type: EnvironmentalData.self, decoder: JSONDecoder()) // Assuming EnvironmentalData is Decodable
            .mapError { error in
                if let decodingError = error as? DecodingError {
                    return APIError.decodingError(decodingError)
                } else if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }

    /// Fetches historical environmental data for a specific date.
    func fetchHistoricalEnvironmentalData(latitude: Double, longitude: Double, date: Date) -> AnyPublisher<EnvironmentalData, Error> {
        // Construct URL for historical data (example for a hypothetical API)
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent("history"), resolvingAgainstBaseURL: true) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Adjust based on API's date format

        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: "\(latitude)"),
            URLQueryItem(name: "lon", value: "\(longitude)"),
            URLQueryItem(name: "date", value: dateFormatter.string(from: date)),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]

        guard let url = urlComponents.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let errorString = String(data: data, encoding: .utf8) ?? "Unknown API Error"
                    throw APIError.apiError("Server responded with status \( (response as? HTTPURLResponse)?.statusCode ?? -1): \(errorString)")
                }
                return data
            }
            .decode(type: EnvironmentalData.self, decoder: JSONDecoder())
            .mapError { error in
                if let decodingError = error as? DecodingError {
                    return APIError.decodingError(decodingError)
                } else if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
}