import SwiftUI

struct SiteEditorView: View {
    @StateObject private var viewModel: SiteEditorViewModel
    @FocusState private var isInputFocused: Bool

    init(site: Site) {
        _viewModel = StateObject(wrappedValue: SiteEditorViewModel(site: site))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, viewModel: viewModel)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            if viewModel.currentPendingChangeId != nil {
                PendingChangeActions(viewModel: viewModel)
            }

            Divider()

            HStack(spacing: 12) {
                Picker("Model", selection: $viewModel.selectedModel) {
                    ForEach(viewModel.availableModels, id: \.0) { model in
                        Text(model.1).tag(model.0)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                TextField("Describe your changes...", text: $viewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused($isInputFocused)

                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(viewModel.isProcessing || viewModel.currentInput.isEmpty ? Color.gray : Color.accentColor)
                        .clipShape(Circle())
                }
                .disabled(viewModel.isProcessing || viewModel.currentInput.isEmpty)
            }
            .padding()
        }
        .navigationTitle(viewModel.site.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await viewModel.loadHistory()
                        viewModel.showHistory = true
                    }
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $viewModel.showHistory) {
            ChangeHistoryView(history: viewModel.history)
        }
        .fullScreenCover(isPresented: $viewModel.showPreview) {
            if let previewUrl = viewModel.previewStatus?.previewUrl ?? viewModel.messages.last?.previewUrl {
                PreviewWebView(url: previewUrl, isPresented: $viewModel.showPreview)
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @ObservedObject var viewModel: SiteEditorViewModel

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.accentColor : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)

                if !message.isUser && message.status == .completed {
                    if let files = message.filesChanged, !files.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Files changed:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(files, id: \.self) { file in
                                Text("• \(file)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if message.previewUrl != nil {
                        Button(action: {
                            viewModel.openPreview()
                        }) {
                            Label("View Preview", systemImage: "eye")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if !message.isUser && message.status == .processing {
                    ProgressView()
                        .padding(.top, 4)
                }
            }

            if !message.isUser { Spacer() }
        }
    }
}

struct PendingChangeActions: View {
    @ObservedObject var viewModel: SiteEditorViewModel

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isPollingPreview {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Building preview...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let status = viewModel.previewStatus {
                if status.isReady {
                    Text("Preview is ready!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else if status.hasError {
                    Text("Preview build failed")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await viewModel.rejectChange()
                    }
                }) {
                    Label("Reject", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(viewModel.isProcessing)

                Button(action: {
                    Task {
                        await viewModel.approveChange()
                    }
                }) {
                    Label("Approve", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(viewModel.isProcessing)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

#Preview {
    NavigationStack {
        SiteEditorView(site: Site(
            id: "1",
            name: "My Site",
            repoName: "my-repo",
            vercelProjectId: nil,
            userId: "user1",
            createdAt: "",
            updatedAt: "",
            pendingChanges: nil
        ))
    }
}
