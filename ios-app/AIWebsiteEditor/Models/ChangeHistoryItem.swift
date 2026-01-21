import Foundation

struct ChangeHistoryItem: Codable, Identifiable {
    let id: String
    let siteId: String
    let userMessage: String
    let aiSummary: String
    let filesChanged: [String]
    let committedAt: String

    enum CodingKeys: String, CodingKey {
        case id, siteId, userMessage, aiSummary, filesChanged, committedAt
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: committedAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return committedAt
    }
}

struct HistoryResponse: Codable {
    let history: [ChangeHistoryItem]
}
