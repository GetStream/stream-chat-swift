//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct UnreadDetailsView: View {
    let onLoadData: (@escaping (Result<CurrentUserUnreads, Error>) -> Void) -> Void
    let onDismiss: () -> Void

    @State private var unreads: CurrentUserUnreads?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading unread data...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadData()
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let unreads = unreads {
                    List {
                        // Summary Section
                        Section(header: Text("Summary")) {
                            SummaryRow(title: "Total Unread Messages", value: "\(unreads.totalUnreadMessagesCount)")
                            SummaryRow(title: "Total Unread Channels", value: "\(unreads.totalUnreadChannelsCount)")
                            SummaryRow(title: "Total Unread Threads", value: "\(unreads.totalUnreadThreadsCount)")
                        }

                        // Unread Channels Section
                        Section(header: Text("Unread Channels (\(unreads.unreadChannels.count))")) {
                            ForEach(unreads.unreadChannels, id: \.channelId.rawValue) { channel in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(channel.channelId.id)
                                            .font(.headline)
                                        Spacer()
                                        Text("\(channel.unreadMessagesCount)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(4)
                                    }

                                    if let lastRead = channel.lastRead {
                                        Text("Last read: \(dateFormatter.string(from: lastRead))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Never read")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }

                        // Unread Threads Section
                        Section(header: Text("Unread Threads (\(unreads.unreadThreads.count))")) {
                            ForEach(unreads.unreadThreads, id: \.parentMessageId) { thread in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Thread: \(thread.parentMessageId)")
                                            .font(.headline)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(thread.unreadRepliesCount)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(4)
                                    }

                                    if let lastRead = thread.lastRead {
                                        Text("Last read: \(dateFormatter.string(from: lastRead))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Never read")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if let lastReadMessageId = thread.lastReadMessageId {
                                        Text("Last read message: \(lastReadMessageId)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }

                        // Channel Types Section
                        Section(header: Text("Unread by Channel Type")) {
                            ForEach(unreads.unreadChannelsByType, id: \.channelType.rawValue) { typeInfo in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(typeInfo.channelType.rawValue.capitalized)
                                            .font(.headline)
                                        Text("\(typeInfo.unreadChannelCount) channels")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("\(typeInfo.unreadMessagesCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                .padding(.vertical, 2)
                            }
                        }

                        // Unread by Team Section
                        let teamUnreads = unreads.totalUnreadCountByTeam ?? [:]
                        Section(header: Text("Unread by Team (\(teamUnreads.count))")) {
                            ForEach(Array(teamUnreads.keys).sorted(), id: \.self) { teamId in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Team: \(teamId)")
                                            .font(.headline)
                                        Text("Team ID: \(teamId)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("\(teamUnreads[teamId] ?? 0)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Unread Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: loadData) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                    }
                }
                .disabled(isLoading),
                trailing: Button("Done") {
                    onDismiss()
                }
            )
            .onAppear {
                loadData()
            }
        }
    }

    private func loadData() {
        isLoading = true
        errorMessage = nil

        onLoadData { result in
            isLoading = false

            switch result {
            case .success(let unreadData):
                unreads = unreadData
                errorMessage = nil
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}
