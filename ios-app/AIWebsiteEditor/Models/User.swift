import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, email, name, createdAt
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct UserResponse: Codable {
    let user: User
}
