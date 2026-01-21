import Foundation

struct ChatResponse: Codable {
    let pendingChangeId: String?
    let branchName: String?
    let previewUrl: String?
    let summary: String
    let filesChanged: [String]?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case pendingChangeId, branchName, previewUrl, summary, filesChanged, message
    }
}

struct ChatRequest: Codable {
    let message: String
    let model: String
}
