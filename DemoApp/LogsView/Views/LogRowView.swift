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

                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Subsystems
            if !log.subsystems.displayNames.isEmpty {
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
