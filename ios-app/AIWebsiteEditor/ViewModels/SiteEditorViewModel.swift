import Foundation
import SwiftUI
import Combine

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    var content: String
    let timestamp: Date
    var pendingChangeId: String?
    var previewUrl: String?
    var filesChanged: [String]?
    var status: MessageStatus

    enum MessageStatus {
        case sent
        case processing
        case completed
        case error
    }
}

@MainActor
class SiteEditorViewModel: ObservableObject {
    @Published var site: Site
    @Published var messages: [ChatMessage] = []
    @Published var currentInput = ""
    @Published var selectedModel = "gemini-flash"
    @Published var isProcessing = false
    @Published var errorMessage: String?

    @Published var currentPendingChangeId: String?
    @Published var previewStatus: PreviewStatus?
    @Published var showPreview = false
    @Published var isPollingPreview = false

    @Published var history: [ChangeHistoryItem] = []
    @Published var showHistory = false

    private var previewTimer: Timer?

    let availableModels = [
        ("gemini-flash", "Gemini Flash"),
        ("gemini-pro", "Gemini Pro"),
        ("claude-opus", "Claude Opus")
    ]

    init(site: Site) {
        self.site = site
    }

    func sendMessage() async {
        let messageText = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }

        print("📝 [SiteEditor] ====== SEND MESSAGE START ======")
        print("📝 [SiteEditor] Site ID: \(site.id)")
        print("📝 [SiteEditor] Site Name: \(site.name)")
        print("📝 [SiteEditor] Repo Name: \(site.repoName)")
        print("📝 [SiteEditor] Message: \(messageText)")
        print("📝 [SiteEditor] Model: \(selectedModel)")

        currentInput = ""
        isProcessing = true
        errorMessage = nil

        let userMessage = ChatMessage(
            isUser: true,
            content: messageText,
            timestamp: Date(),
            status: .sent
        )
        messages.append(userMessage)

        var aiMessage = ChatMessage(
            isUser: false,
            content: "Processing your request...",
            timestamp: Date(),
            status: .processing
        )
        messages.append(aiMessage)

        do {
            print("📝 [SiteEditor] Calling APIClient.sendChat...")
            let response = try await APIClient.shared.sendChat(
                siteId: site.id,
                message: messageText,
                model: selectedModel
            )
            
            print("📝 [SiteEditor] ✅ Response received:")
            print("📝 [SiteEditor] - Summary: \(response.summary)")
            print("📝 [SiteEditor] - Pending Change ID: \(response.pendingChangeId ?? "nil")")
            print("📝 [SiteEditor] - Preview URL: \(response.previewUrl ?? "nil")")
            print("📝 [SiteEditor] - Files Changed: \(response.filesChanged ?? [])")

            if let index = messages.lastIndex(where: { !$0.isUser && $0.status == .processing }) {
                messages[index].content = response.summary
                messages[index].pendingChangeId = response.pendingChangeId
                messages[index].previewUrl = response.previewUrl
                messages[index].filesChanged = response.filesChanged
                messages[index].status = .completed

                if let changeId = response.pendingChangeId {
                    currentPendingChangeId = changeId
                    startPollingPreview(changeId: changeId)
                }
            }
        } catch let error as APIError {
            print("📝 [SiteEditor] 🔴 APIError: \(error.localizedDescription ?? "unknown")")
            errorMessage = error.localizedDescription
            if let index = messages.lastIndex(where: { !$0.isUser && $0.status == .processing }) {
                messages[index].content = "Error: \(error.localizedDescription ?? "Unknown error")"
                messages[index].status = .error
            }
        } catch {
            print("📝 [SiteEditor] 🔴 General Error: \(error)")
            print("📝 [SiteEditor] 🔴 Error Type: \(type(of: error))")
            errorMessage = error.localizedDescription
            if let index = messages.lastIndex(where: { !$0.isUser && $0.status == .processing }) {
                messages[index].content = "Error: \(error.localizedDescription)"
                messages[index].status = .error
            }
        }

        isProcessing = false
        print("📝 [SiteEditor] ====== SEND MESSAGE END ======\n")
    }

    func startPollingPreview(changeId: String) {
        isPollingPreview = true
        stopPollingPreview()

        previewTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkPreviewStatus(changeId: changeId)
            }
        }

        Task {
            await checkPreviewStatus(changeId: changeId)
        }
    }

    func stopPollingPreview() {
        previewTimer?.invalidate()
        previewTimer = nil
        isPollingPreview = false
    }

    func checkPreviewStatus(changeId: String) async {
        do {
            let status = try await APIClient.shared.getPreviewStatus(siteId: site.id, changeId: changeId)
            previewStatus = status

            if status.isReady || status.hasError {
                stopPollingPreview()
            }
        } catch {
            // Silent failure, will retry
        }
    }

    func approveChange() async {
        guard let changeId = currentPendingChangeId else { return }

        isProcessing = true
        errorMessage = nil

        do {
            try await APIClient.shared.approveChange(siteId: site.id, changeId: changeId)

            let successMessage = ChatMessage(
                isUser: false,
                content: "Changes approved and merged to main branch!",
                timestamp: Date(),
                status: .completed
            )
            messages.append(successMessage)

            currentPendingChangeId = nil
            previewStatus = nil
            stopPollingPreview()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func rejectChange() async {
        guard let changeId = currentPendingChangeId else { return }

        isProcessing = true
        errorMessage = nil

        do {
            try await APIClient.shared.rejectChange(siteId: site.id, changeId: changeId)

            let rejectMessage = ChatMessage(
                isUser: false,
                content: "Changes rejected. Branch has been deleted.",
                timestamp: Date(),
                status: .completed
            )
            messages.append(rejectMessage)

            currentPendingChangeId = nil
            previewStatus = nil
            stopPollingPreview()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func loadHistory() async {
        do {
            history = try await APIClient.shared.getHistory(siteId: site.id)
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openPreview() {
        showPreview = true
    }

    func clearError() {
        errorMessage = nil
    }

    deinit {
        previewTimer?.invalidate()
    }
}
