import Foundation

struct Site: Codable, Identifiable {
    let id: String
    let name: String
    let repoName: String
    let vercelProjectId: String?
    let userId: String
    let createdAt: String
    let updatedAt: String
    let pendingChanges: [PendingChange]?

    enum CodingKeys: String, CodingKey {
        case id, name, repoName, vercelProjectId, userId, createdAt, updatedAt, pendingChanges
    }
}

struct PendingChange: Codable, Identifiable {
    let id: String
    let siteId: String
    let branchName: String
    let previewUrl: String?
    let userMessage: String
    let aiSummary: String
    let filesChanged: [String]
    let status: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, siteId, branchName, previewUrl, userMessage, aiSummary, filesChanged, status, createdAt, updatedAt
    }
}

struct SitesResponse: Codable {
    let sites: [Site]
}

struct SiteResponse: Codable {
    let site: Site
}
