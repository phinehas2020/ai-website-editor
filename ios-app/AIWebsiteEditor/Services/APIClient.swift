import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Unauthorized. Please log in again."
        }
    }
}

struct ErrorResponse: Codable {
    let error: String
}

class APIClient {
    static let shared = APIClient()

    #if DEBUG
    private let baseURL = "http://localhost:3000"
    #else
    // TODO: Replace with your actual Vercel deployment URL
    private let baseURL = "https://ai-website-editor-backend.vercel.app"
    #endif

    private init() {}

    private var token: String? {
        return KeychainService.shared.getToken()
    }

    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            _ = KeychainService.shared.deleteToken()
            throw APIError.unauthorized
        }

        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.serverError("Server error: \(httpResponse.statusCode)")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Auth

    struct RegisterRequest: Codable {
        let email: String
        let password: String
        let name: String?
    }

    func register(email: String, password: String, name: String?) async throws -> AuthResponse {
        let body = RegisterRequest(email: email, password: password, name: name)
        let response: AuthResponse = try await makeRequest(
            endpoint: "/api/auth/register",
            method: "POST",
            body: body
        )
        _ = KeychainService.shared.saveToken(response.token)
        return response
    }

    struct LoginRequest: Codable {
        let email: String
        let password: String
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await makeRequest(
            endpoint: "/api/auth/login",
            method: "POST",
            body: body
        )
        _ = KeychainService.shared.saveToken(response.token)
        return response
    }

    func getMe() async throws -> User {
        let response: UserResponse = try await makeRequest(endpoint: "/api/auth/me")
        return response.user
    }

    func logout() {
        _ = KeychainService.shared.deleteToken()
    }

    // MARK: - Sites

    func getSites() async throws -> [Site] {
        let response: SitesResponse = try await makeRequest(endpoint: "/api/sites")
        return response.sites
    }

    struct CreateSiteRequest: Codable {
        let name: String
        let repoName: String
        let vercelProjectId: String?
    }

    func createSite(name: String, repoName: String, vercelProjectId: String?) async throws -> Site {
        let body = CreateSiteRequest(name: name, repoName: repoName, vercelProjectId: vercelProjectId)
        let response: SiteResponse = try await makeRequest(
            endpoint: "/api/sites",
            method: "POST",
            body: body
        )
        return response.site
    }

    func getSite(id: String) async throws -> Site {
        let response: SiteResponse = try await makeRequest(endpoint: "/api/sites/\(id)")
        return response.site
    }

    func deleteSite(id: String) async throws {
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/api/sites/\(id)",
            method: "DELETE"
        )
    }

    // MARK: - Chat

    func sendChat(siteId: String, message: String, model: String) async throws -> ChatResponse {
        let body = ChatRequest(message: message, model: model)
        return try await makeRequest(
            endpoint: "/api/sites/\(siteId)/chat",
            method: "POST",
            body: body
        )
    }

    // MARK: - Preview

    func getPreviewStatus(siteId: String, changeId: String) async throws -> PreviewStatus {
        return try await makeRequest(
            endpoint: "/api/sites/\(siteId)/preview/\(changeId)"
        )
    }

    // MARK: - Approve/Reject

    func approveChange(siteId: String, changeId: String) async throws {
        let _: ApproveRejectResponse = try await makeRequest(
            endpoint: "/api/sites/\(siteId)/approve/\(changeId)",
            method: "POST"
        )
    }

    func rejectChange(siteId: String, changeId: String) async throws {
        let _: ApproveRejectResponse = try await makeRequest(
            endpoint: "/api/sites/\(siteId)/reject/\(changeId)",
            method: "POST"
        )
    }

    // MARK: - History

    func getHistory(siteId: String) async throws -> [ChangeHistoryItem] {
        let response: HistoryResponse = try await makeRequest(
            endpoint: "/api/sites/\(siteId)/history"
        )
        return response.history
    }
}

struct EmptyResponse: Codable {
    let message: String?
}

struct ApproveRejectResponse: Codable {
    let message: String
    let changeId: String
}
