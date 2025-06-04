//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 16.0, *)
struct LogListView: View {
    private var logStore = InMemoryLogEntryStoreProvider.shared

    @State private var selectedLevel: LogLevel?
    @State private var searchText: String = ""
    @State private var logs: [LogEntry] = []

    var filteredLogs: [LogEntry] {
        var filtered = logs

        // Apply level filter
        if let selectedLevel = selectedLevel {
            filtered = filtered.filter { $0.level == selectedLevel }
        }

        // Apply text search
        if !searchText.isEmpty {
            filtered = filtered.filter { log in
                log.subsystems.displayNames.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
                    log.functionName.localizedCaseInsensitiveContains(searchText) ||
                    log.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section(header:
                        VStack(spacing: 0) {
                            // Filter bar
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Button("All") {
                                        selectedLevel = nil
                                    }
                                    .buttonStyle(FilterButtonStyle(isSelected: selectedLevel == nil))

                                    ForEach(LogLevel.allCases, id: \ .self) { level in
                                        Button(level.displayName) {
                                            selectedLevel = selectedLevel == level ? nil : level
                                        }
                                        .buttonStyle(FilterButtonStyle(isSelected: selectedLevel == level))
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))

                            Divider()
                                .background(Color(.systemBackground))

                            // Results info
                            if !searchText.isEmpty || selectedLevel != nil {
                                HStack {
                                    Text("\(filteredLogs.count) result\(filteredLogs.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    if !searchText.isEmpty && selectedLevel != nil {
                                        Button("Clear all filters") {
                                            searchText = ""
                                            selectedLevel = nil
                                        }
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .background(Color(.systemBackground))
                            }
                        }
                        .background(Color(.systemBackground))
                    ) {
                        if filteredLogs.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)

                                Text(searchText.isEmpty ? "No logs available" : "No matching logs found")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                if !searchText.isEmpty {
                                    Text("Try adjusting your search terms or filters")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .background(Color(.systemBackground))
                        } else {
                            ForEach(filteredLogs) { log in
                                ZStack {
                                    NavigationLink(destination: LogDetailView(log: log)) {
                                        EmptyView()
                                    }
                                    .opacity(0)

                                    LogRowView(log: log, searchText: searchText)
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                }
                                .contentShape(Rectangle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        logStore.deleteLog(with: log.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search logs...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        logStore.clear()
                    }) {
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
            .onReceive(logStore.$logs.receive(on: DispatchQueue.main)) { logs in
                self.logs = logs
            }
        }
    }
}

// Helper for sticky header offset
private struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
