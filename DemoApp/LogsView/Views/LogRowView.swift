//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

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

                Text(Self.timeFormatter.string(from: log.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Subsystems
            if !log.subsystems.displayNames.isEmpty {
                HStack(spacing: 6) {
                    ForEach(log.subsystems.displayNames, id: \.self) { subsystem in
                        HighlightedSearchText(text: subsystem, searchText: searchText)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }

            // Function name
            let fileAndFunctionName = "[\(log.fileName):\(log.lineNumber)] \(log.functionName)"
            HighlightedSearchText(text: fileAndFunctionName, searchText: searchText)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            // Description preview
            HighlightedSearchText(text: log.description, searchText: searchText)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
