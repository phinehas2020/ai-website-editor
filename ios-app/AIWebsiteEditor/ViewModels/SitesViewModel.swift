import Foundation
import SwiftUI

@MainActor
class SitesViewModel: ObservableObject {
    @Published var sites: [Site] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddSite = false

    func loadSites() async {
        isLoading = true
        errorMessage = nil

        do {
            sites = try await APIClient.shared.getSites()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createSite(name: String, repoName: String, vercelProjectId: String?) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newSite = try await APIClient.shared.createSite(
                name: name,
                repoName: repoName,
                vercelProjectId: vercelProjectId?.isEmpty == true ? nil : vercelProjectId
            )
            sites.insert(newSite, at: 0)
            showAddSite = false
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func deleteSite(_ site: Site) async {
        do {
            try await APIClient.shared.deleteSite(id: site.id)
            sites.removeAll { $0.id == site.id }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
