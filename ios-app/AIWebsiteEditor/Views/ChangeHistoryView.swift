import SwiftUI

struct ChangeHistoryView: View {
    let history: [ChangeHistoryItem]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    ContentUnavailableView {
                        Label("No History", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Changes you approve will appear here")
                    }
                } else {
                    List(history) { item in
                        HistoryItemRow(item: item)
                    }
                }
            }
            .navigationTitle("Change History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HistoryItemRow: View {
    let item: ChangeHistoryItem
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.userMessage)
                        .font(.headline)
                        .lineLimit(isExpanded ? nil : 2)

                    Text(item.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    Text("AI Summary:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(item.aiSummary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !item.filesChanged.isEmpty {
                        Text("Files Changed:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 4)

                        ForEach(item.filesChanged, id: \.self) { file in
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(file)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ChangeHistoryView(history: [
        ChangeHistoryItem(
            id: "1",
            siteId: "site1",
            userMessage: "Change the hero title to Welcome",
            aiSummary: "Updated the hero component title",
            filesChanged: ["src/components/Hero.tsx"],
            committedAt: "2024-01-15T10:30:00.000Z"
        ),
        ChangeHistoryItem(
            id: "2",
            siteId: "site1",
            userMessage: "Update the footer copyright",
            aiSummary: "Changed footer copyright year",
            filesChanged: ["src/components/Footer.tsx", "content/site.json"],
            committedAt: "2024-01-14T15:45:00.000Z"
        )
    ])
}
