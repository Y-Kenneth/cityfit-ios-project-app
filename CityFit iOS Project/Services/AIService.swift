import Foundation

/// URLSession client for the Flask + CrewAI backend (exposed via Ngrok).
/// Every call can fail when the backend is offline — callers must degrade gracefully.
enum AIService {

    enum AIServiceError: LocalizedError {
        case invalidURL
        case badResponse
        case unreachable

        var errorDescription: String? {
            switch self {
            case .invalidURL:  return "Backend URL is invalid — check Constants.swift."
            case .badResponse: return "The AI backend returned an unexpected response."
            case .unreachable: return "AI is unavailable right now — check your connection."
            }
        }
    }

    static func chat(_ request: ChatRequest) async throws -> String {
        let response: ChatResponse = try await post(path: "/chat", body: request)
        return response.response
    }

    static func generateRoute(_ request: RouteRequest) async throws -> RouteResponse {
        try await post(path: "/route", body: request)
    }

    static func verifyPhoto(_ request: VerifyPhotoRequest) async throws -> VerifyPhotoResponse {
        try await post(path: "/verify-photo", body: request)
    }

    // MARK: - Plumbing

    private static func post<Body: Encodable, Response: Decodable>(
        path: String, body: Body
    ) async throws -> Response {
        guard let url = URL(string: Constants.backendURL + path) else {
            throw AIServiceError.invalidURL
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = Constants.requestTimeout
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Ngrok free tier shows an interstitial page unless this header is set
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw AIServiceError.unreachable
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AIServiceError.badResponse
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw AIServiceError.badResponse
        }
    }
}
