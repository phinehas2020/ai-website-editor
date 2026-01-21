import Foundation

struct PreviewStatus: Codable {
    let id: String
    let branchName: String
    let previewUrl: String?
    let status: String // "pending", "ready", "error"
    let userMessage: String
    let aiSummary: String
    let filesChanged: [String]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, branchName, previewUrl, status, userMessage, aiSummary, filesChanged, createdAt
    }

    var isReady: Bool {
        return status == "ready"
    }

    var isPending: Bool {
        return status == "pending"
    }

    var hasError: Bool {
        return status == "error"
    }
}
