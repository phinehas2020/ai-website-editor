import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    init() {
        isAuthenticated = KeychainService.shared.hasToken
        if isAuthenticated {
            Task {
                await checkAuth()
            }
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIClient.shared.login(email: email, password: password)
            currentUser = response.user
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            if case .unauthorized = error {
                isAuthenticated = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func register(email: String, password: String, name: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIClient.shared.register(email: email, password: password, name: name)
            currentUser = response.user
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func checkAuth() async {
        guard KeychainService.shared.hasToken else {
            isAuthenticated = false
            return
        }

        do {
            currentUser = try await APIClient.shared.getMe()
            isAuthenticated = true
        } catch let error as APIError {
            if case .unauthorized = error {
                isAuthenticated = false
            }
        } catch {
            // Keep authenticated state if just a network error
        }
    }

    func logout() {
        APIClient.shared.logout()
        isAuthenticated = false
        currentUser = nil
    }

    func clearError() {
        errorMessage = nil
    }
}
