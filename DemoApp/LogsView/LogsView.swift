//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

extension LogLevel {
    var displayName: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        }
    }

    var color: Color {
        switch self {
        case .debug:
            return .gray
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

    var icon: String {
        switch self {
        case .debug:
            return "ant.circle"
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        }
    }
}

extension LogSubsystem {
    var displayNames: [String] {
        var names: [String] = []
        if contains(.other) { names.append("Other") }
        if contains(.database) { names.append("Database") }
        if contains(.httpRequests) { names.append("HTTP") }
        if contains(.webSocket) { names.append("WebSocket") }
        if contains(.offlineSupport) { names.append("Offline") }
        if contains(.authentication) { names.append("Auth") }
        if contains(.audioPlayback) { names.append("Audio Playback") }
        if contains(.audioRecording) { names.append("Audio Recording") }
        return names
    }

    var primaryDisplayName: String {
        let names = displayNames
        return names.first ?? "Unknown"
    }
}

extension InMemoryLogEntryStoreProvider: @retroactive ObservableObject {}

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

@available(iOS 15, *)
struct LogRowView: View {
    let log: LogEntry
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row with level, timestamp
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: log.level.icon)
                        .foregroundColor(log.level.color)
                        .font(.caption)

                    Text(log.level.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(log.level.color)
                }

                Spacer()

                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Subsystems
            if !log.subsystems.displayNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(log.subsystems.displayNames, id: \.self) { subsystem in
                            HighlightedText(text: subsystem, searchText: searchText)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            // Function name
            HighlightedText(text: log.functionName, searchText: searchText)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)

            // Description preview
            HighlightedText(text: log.description, searchText: searchText)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 16.0, *)
struct LogDetailView: View {
    let log: LogEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: log.level.icon)
                                .foregroundColor(log.level.color)
                                .font(.title2)

                            Text(log.level.displayName)
                                .font(.title2.weight(.semibold))
                                .foregroundColor(log.level.color)
                        }

                        Spacer()

                        Text(log.timestamp, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(log.timestamp, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        if !log.subsystems.displayNames.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Subsystems:")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)

                                FlowLayout(spacing: 6) {
                                    ForEach(log.subsystems.displayNames, id: \.self) { subsystem in
                                        Text(subsystem)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }

                        DetailRow(title: "Function", value: log.functionName)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Description section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)

                    SelectableTextView(text: log.description)
                        .frame(minHeight: 200)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
            .padding()
        }
        .navigationTitle("Log Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title + ":")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

@available(iOS 16.0, *)
struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
}

@available(iOS 16.0, *)
struct FlowResult {
    var bounds = CGSize.zero
    var frames: [CGRect] = []

    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }

        bounds = CGSize(width: maxWidth, height: y + lineHeight)
    }
}

struct SelectableTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.text = text
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}

@available(iOS 15, *)
struct HighlightedText: View {
    let text: String
    let searchText: String

    var body: some View {
        if searchText.isEmpty {
            Text(text)
        } else {
            let attributedString = highlightedAttributedString()
            Text(AttributedString(attributedString))
        }
    }

    private func highlightedAttributedString() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.count)

        // Find all occurrences of search text (case insensitive)
        let searchRange = text.range(of: searchText, options: .caseInsensitive)
        if let searchRange = searchRange {
            let nsRange = NSRange(searchRange, in: text)
            attributedString.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.3), range: nsRange)
        }

        return attributedString
    }
}

struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Sample Data

let sampleLogs: [LogEntry] = [
    LogEntry(
        timestamp: Date().addingTimeInterval(-3600),
        level: .error,
        subsystems: [.httpRequests],
        functionName: "performRequest(_:)",
        description: """
        HTTP Request Failed:
        URL: https://api.example.com/users/profile
        Method: GET
        Status Code: 404
        Headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            "User-Agent": "MyApp/1.0"
        }
        Response Body: {
            "error": {
                "code": "USER_NOT_FOUND",
                "message": "The requested user profile could not be found",
                "details": {
                    "userId": "12345",
                    "timestamp": "2024-03-15T10:30:00Z"
                }
            }
        }
        """
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-1800),
        level: .info,
        subsystems: [.authentication],
        functionName: "loginUser(email:password:)",
        description: "User successfully authenticated with email: user@example.com"
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-900),
        level: .warning,
        subsystems: [.database],
        functionName: "saveContext()",
        description: "Core Data context save took longer than expected: 2.3 seconds. Consider optimizing batch operations."
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-300),
        level: .debug,
        subsystems: [.other],
        functionName: "viewDidLoad()",
        description: "Profile view controller loaded successfully. User preferences: dark mode enabled, notifications allowed."
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-60),
        level: .error,
        subsystems: [.httpRequests, .authentication],
        functionName: "processPayment(_:)",
        description: """
        Payment processing failed with critical error:
        Transaction ID: TXN_789012345
        Amount: $99.99 USD
        Payment Method: **** **** **** 1234
        Error Code: GATEWAY_TIMEOUT
        Gateway Response: {
            "status": "failed",
            "error_code": "TIMEOUT",
            "message": "Payment gateway did not respond within timeout period",
            "retry_after": 300,
            "support_reference": "REF_ABC123XYZ"
        }
        """
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-120),
        level: .info,
        subsystems: [.webSocket, .offlineSupport],
        functionName: "connectWebSocket()",
        description: "WebSocket connection established successfully with offline sync enabled"
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-30),
        level: .debug,
        subsystems: [.audioPlayback, .audioRecording],
        functionName: "setupAudioSession()",
        description: "Audio session configured for playback and recording with background support"
    )
]

#Preview {
    if #available(iOS 16.0, *) {
        LogListView()
    } else {
        EmptyView()
    }
}
