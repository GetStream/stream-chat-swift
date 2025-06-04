//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 16.0, *)
struct LogListView: View {
    private var logStore = InMemoryLogEntryStoreProvider.shared

    @State private var selectedLevel: LogLevel?
    @State private var selectedSubsystems: Set<String> = ["HTTP", "WebSocket"]
    @State private var showingLevelPicker = false
    @State private var showingSubsystemPicker = false
    @State private var searchText: String = ""
    @State private var logs: [LogEntry] = []
    @State private var isRecording: Bool = true
    @State private var showCopyAlert = false

    var availableSubsystems: [String] {
        let allSubsystems = LogSubsystem.all.displayNames
        return Array(Set(allSubsystems)).sorted()
    }

    var filteredLogs: [LogEntry] {
        var filtered = logs

        // Apply level filter
        if let selectedLevel = selectedLevel {
            filtered = filtered.filter { $0.level == selectedLevel }
        }

        // Apply subsystem filter
        if !selectedSubsystems.isEmpty {
            filtered = filtered.filter { log in
                let logSubsystems = Set(log.subsystems.displayNames)
                return !selectedSubsystems.isDisjoint(with: logSubsystems)
            }
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
                    Section(header: headerView) {
                        logListContent
                    }
                }
            }
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search logs..."
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            isRecording.toggle()
                            InMemoryRecorderLogDestination.isRecording = isRecording
                        }) {
                            Image(systemName: isRecording ? "record.circle.fill" : "record.circle")
                                .foregroundColor(isRecording ? .red : .gray)
                        }
                        
                        Button(action: {
                            logStore.clear()
                        }) {
                            Image(systemName: "trash")
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
            .onAppear {
                isRecording = InMemoryRecorderLogDestination.isRecording
            }
            .onReceive(logStore.$logs.receive(on: DispatchQueue.main)) { logs in
                self.logs = logs
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 0) {
            // Filter bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Level selector button
                    Button(action: {
                        showingLevelPicker = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption2)
                            Text(selectedLevel?.displayName ?? "All Levels")
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                    }
                    .buttonStyle(FilterButtonStyle(
                        isSelected: selectedLevel != nil,
                        backgroundColor: selectedLevel != nil ? selectedLevel?.color.opacity(0.2) : nil,
                        foregroundColor: selectedLevel != nil ? selectedLevel?.color : nil
                    ))
                    .sheet(isPresented: $showingLevelPicker) {
                        LevelPickerView(selectedLevel: $selectedLevel)
                    }

                    // Subsystem selector button
                    Button(action: {
                        showingSubsystemPicker = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gearshape.2")
                                .font(.caption2)
                            Text("Subsystems")
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                    }
                    .buttonStyle(FilterButtonStyle(isSelected: !selectedSubsystems.isEmpty))
                    .sheet(isPresented: $showingSubsystemPicker) {
                        SubsystemPickerView(
                            selectedSubsystems: $selectedSubsystems,
                            availableSubsystems: availableSubsystems
                        )
                    }

                    // Selected subsystem pills
                    ForEach(selectedSubsystems.sorted(), id: \.self) { subsystem in
                        Button(action: {
                            selectedSubsystems.remove(subsystem)
                        }) {
                            HStack(spacing: 4) {
                                Text(subsystem)
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                        }
                        .buttonStyle(FilterButtonStyle(isSelected: true))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            Divider()
                .background(Color(.systemBackground))

            // Results info
            if !searchText.isEmpty {
                HStack {
                    Text("\(filteredLogs.count) result\(filteredLogs.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var logListContent: some View {
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
                logRowView(for: log)
            }
        }
    }
    
    @ViewBuilder
    private func logRowView(for log: LogEntry) -> some View {
        NavigationLink(destination: LogDetailView(log: log)) {
            VStack(spacing: 0) {
                LogRowView(log: log, searchText: searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                Divider()
                    .padding(.leading)
                    .background(Color(.systemGray5))
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                UIPasteboard.general.string = log.description
                showCopyAlert = true
            } label: {
                Label("Copy Message", systemImage: "doc.on.doc")
            }
            
            Button(role: .destructive) {
                logStore.deleteLog(with: log.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Copied!", isPresented: $showCopyAlert) {
            Button("OK") {}
        } message: {
            Text("Log message copied to clipboard")
        }
    }
}

@available(iOS 16.0, *)
struct LevelPickerView: View {
    @Binding var selectedLevel: LogLevel?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Log Level") {
                    Button("All Levels") {
                        selectedLevel = nil
                        dismiss()
                    }
                    .foregroundColor(selectedLevel == nil ? .accentColor : .primary)
                    .fontWeight(selectedLevel == nil ? .semibold : .regular)
                    
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Button(level.displayName) {
                            selectedLevel = level
                            dismiss()
                        }
                        .foregroundColor(selectedLevel == level ? .accentColor : .primary)
                        .fontWeight(selectedLevel == level ? .semibold : .regular)
                    }
                }
            }
            .navigationTitle("Select Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

@available(iOS 16.0, *)
struct SubsystemPickerView: View {
    @Binding var selectedSubsystems: Set<String>
    let availableSubsystems: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Subsystems") {
                    ForEach(availableSubsystems, id: \.self) { subsystem in
                        Button(action: {
                            if selectedSubsystems.contains(subsystem) {
                                selectedSubsystems.remove(subsystem)
                            } else {
                                selectedSubsystems.insert(subsystem)
                            }
                        }) {
                            HStack {
                                Text(subsystem)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedSubsystems.contains(subsystem) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Subsystems")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// Helper for sticky header offset
private struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
