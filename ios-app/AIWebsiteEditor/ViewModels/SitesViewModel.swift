import Foundation
import SwiftUI

@MainActor
class SitesViewModel: ObservableObject {
    @Published var sites: [Site] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddSite = false

    func loadSites() async {
        print("📋 [SitesVM] Loading sites...")
        isLoading = true
        errorMessage = nil

        do {
            sites = try await APIClient.shared.getSites()
            print("📋 [SitesVM] ✅ Loaded \(sites.count) sites:")
            for site in sites {
                print("📋 [SitesVM]   - \(site.name) | Repo: \(site.repoName) | ID: \(site.id)")
            }
        } catch let error as APIError {
            print("📋 [SitesVM] 🔴 APIError loading sites: \(error.localizedDescription ?? "unknown")")
            errorMessage = error.localizedDescription
        } catch {
            print("📋 [SitesVM] 🔴 Error loading sites: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createSite(name: String, repoName: String, vercelProjectId: String?) async -> Bool {
        print("📋 [SitesVM] Creating site...")
        print("📋 [SitesVM]   Name: \(name)")
        print("📋 [SitesVM]   Repo: \(repoName)")
        print("📋 [SitesVM]   Vercel ID: \(vercelProjectId ?? "nil")")
        
        isLoading = true
        errorMessage = nil

        do {
            let newSite = try await APIClient.shared.createSite(
                name: name,
                repoName: repoName,
                vercelProjectId: vercelProjectId?.isEmpty == true ? nil : vercelProjectId
            )
            print("📋 [SitesVM] ✅ Site created: \(newSite.id)")
            sites.insert(newSite, at: 0)
            showAddSite = false
            isLoading = false
            return true
        } catch let error as APIError {
            print("📋 [SitesVM] 🔴 APIError creating site: \(error.localizedDescription ?? "unknown")")
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        } catch {
            print("📋 [SitesVM] 🔴 Error creating site: \(error)")
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
