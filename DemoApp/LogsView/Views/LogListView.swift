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
            List {
                // Search and Filter Header Section
                Section {
                    EmptyView()
                } header: {
                    VStack(spacing: 12) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))

                            TextField("Search logs...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocorrectionDisabled()

                            if !searchText.isEmpty {
                                Button("Clear") {
                                    searchText = ""
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                        // Filter pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button("All") {
                                    selectedLevel = nil
                                }
                                .buttonStyle(FilterButtonStyle(isSelected: selectedLevel == nil))

                                ForEach(LogLevel.allCases, id: \.self) { level in
                                    Button(level.displayName) {
                                        selectedLevel = selectedLevel == level ? nil : level
                                    }
                                    .buttonStyle(FilterButtonStyle(isSelected: selectedLevel == level))
                                }
                            }
                            .padding(.horizontal, 1)
                        }

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
                        }
                    }
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))
                }

                // Log entries section
                Section {
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredLogs) { log in
                            NavigationLink(destination: LogDetailView(log: log)) {
                                LogRowView(log: log, searchText: searchText)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        logStore.clear()
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

#Preview {
    if #available(iOS 16.0, *) {
        LogListView()
    } else {
        EmptyView()
    }
}
