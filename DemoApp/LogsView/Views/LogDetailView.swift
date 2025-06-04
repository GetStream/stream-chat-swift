//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 16.0, *)
struct LogDetailView: View {
    let log: LogEntry
    @State private var isCopied = false

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

                        Text(Self.dateFormatter.string(from: log.timestamp))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(Self.timeFormatter.string(from: log.timestamp))
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
                    HStack {
                        Text("Description")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = log.description
                            isCopied = true
                            
                            // Reset after 1.5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isCopied = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Copied!" : "Copy")
                            }
                            .font(.caption)
                            .foregroundColor(isCopied ? .green : .blue)
                        }
                    }

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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
