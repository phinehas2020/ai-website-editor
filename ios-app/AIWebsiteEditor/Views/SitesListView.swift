import SwiftUI

struct SitesListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SitesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sites.isEmpty {
                    ProgressView("Loading sites...")
                } else if viewModel.sites.isEmpty {
                    ContentUnavailableView {
                        Label("No Sites", systemImage: "globe")
                    } description: {
                        Text("Add your first site to get started")
                    } actions: {
                        Button("Add Site") {
                            viewModel.showAddSite = true
                        }
                    }
                } else {
                    List {
                        ForEach(viewModel.sites) { site in
                            NavigationLink(destination: SiteEditorView(site: site)) {
                                SiteRow(site: site)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteSite(viewModel.sites[index])
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.loadSites()
                    }
                }
            }
            .navigationTitle("My Sites")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showAddSite = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddSite) {
                AddSiteView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.loadSites()
            }
        }
    }
}

struct SiteRow: View {
    let site: Site

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(site.name)
                .font(.headline)

            Text(site.repoName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let pendingChanges = site.pendingChanges, !pendingChanges.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(pendingChanges.count) pending change(s)")
                        .font(.caption)
                }
                .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddSiteView: View {
    @ObservedObject var viewModel: SitesViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var repoName = ""
    @State private var vercelProjectId = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Site Details") {
                    TextField("Site Name", text: $name)
                    TextField("GitHub Repository Name", text: $repoName)
                        .autocapitalization(.none)
                }

                Section("Vercel (Optional)") {
                    TextField("Vercel Project ID", text: $vercelProjectId)
                        .autocapitalization(.none)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let success = await viewModel.createSite(
                                name: name,
                                repoName: repoName,
                                vercelProjectId: vercelProjectId
                            )
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(name.isEmpty || repoName.isEmpty || viewModel.isLoading)
                }
            }
        }
    }
}

#Preview {
    SitesListView()
        .environmentObject(AuthViewModel())
}
