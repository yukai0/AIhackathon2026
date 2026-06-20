import Foundation

enum APIError: LocalizedError {
    case badResponse(Int)
    case decodingFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): return "Server returned \(code)"
        case .decodingFailed(let e): return "Decoding failed: \(e.localizedDescription)"
        case .networkError(let e): return e.localizedDescription
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    private let encoder: JSONEncoder = JSONEncoder()
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = Config.apiTimeout
        return URLSession(configuration: cfg)
    }()

    private init() {}

    func fetchMenu(date: String = "today", location: String = "all") async throws -> [MenuItem] {
        var components = URLComponents(url: Config.baseURL.appendingPathComponent("menu"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "location", value: location),
        ]
        return try await get(url: components.url!)
    }

    func generatePlan(profile: UserProfile, date: String) async throws -> MealPlan {
        let body = PlanRequest(profile: profile, date: date)
        let url = Config.baseURL.appendingPathComponent("plan")
        return try await post(url: url, body: body)
    }

    // MARK: - Private helpers

    private func get<T: Decodable>(url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            try validateResponse(response)
            return try decode(data)
        } catch let e as APIError { throw e }
        catch { throw APIError.networkError(error) }
    }

    private func post<Body: Encodable, Response: Decodable>(url: URL, body: Body) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            return try decode(data)
        } catch let e as APIError { throw e }
        catch { throw APIError.networkError(error) }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.badResponse(http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
