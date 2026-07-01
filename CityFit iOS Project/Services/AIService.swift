import Foundation

// Handles all HTTP calls to the Flask backend (exposed via Ngrok).
// All calls fail gracefully if the backend is offline.
enum AIService {

    enum AIServiceError: LocalizedError {
        case invalidURL
        case badResponse(status: Int)
        case tunnelOffline
        case backendError(message: String)
        case unreachable(underlying: String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Backend URL is invalid — check Constants.swift."
            case .badResponse(let status):
                return "The AI backend returned an unexpected response (HTTP \(status))."
            case .tunnelOffline:
                return "The ngrok tunnel is offline — restart ngrok and update Constants.swift with the new URL."
            case .backendError(let message):
                return "The AI backend reported an error: \(message)"
            case .unreachable(let underlying):
                return "Couldn't reach the AI backend (\(underlying)). Check Ngrok and your connection."
            }
        }
    }

    static func chat(_ request: ChatRequest) async throws -> String {
        let response: ChatResponse = try await post(path: "/chat", body: request)
        return response.response
    }

    static func generateRoute(_ request: RouteRequest) async throws -> RouteResponse {
        do {
            return try await post(path: "/route", body: request, timeout: Constants.routeRequestTimeout)
        } catch {
            // retry once more on the client side, route crew can be slow
            return try await post(path: "/route", body: request, timeout: Constants.routeRequestTimeout)
        }
    }

    static func verifyPhoto(_ request: VerifyPhotoRequest) async throws -> VerifyPhotoResponse {
        try await post(path: "/verify-photo", body: request)
    }

    static func planTrip(_ request: TripRequest) async throws -> TripResponse {
        try await post(path: "/plan-trip", body: request, timeout: Constants.tripRequestTimeout)
    }

    // MARK: - Plumbing

    private static func post<Body: Encodable, Response: Decodable>(
        path: String, body: Body, timeout: TimeInterval = Constants.requestTimeout
    ) async throws -> Response {
        guard let url = URL(string: Constants.backendURL + path) else {
            throw AIServiceError.invalidURL
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = timeout
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // ngrok blocks requests without this header
        urlRequest.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw AIServiceError.unreachable(underlying: error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.badResponse(status: -1)
        }

        // ngrok returns an HTML page with this string when the tunnel is down
        if let body = String(data: data, encoding: .utf8), body.contains("ERR_NGROK") {
            throw AIServiceError.tunnelOffline
        }

        // backend sends error message inside JSON body on failure
        if let errorBody = try? JSONDecoder().decode(BackendError.self, from: data) {
            throw AIServiceError.backendError(message: errorBody.error)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw AIServiceError.badResponse(status: http.statusCode)
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw AIServiceError.badResponse(status: http.statusCode)
        }
    }

    private struct BackendError: Decodable {
        let error: String
    }
}
