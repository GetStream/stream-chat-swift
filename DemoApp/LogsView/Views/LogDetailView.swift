//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

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
