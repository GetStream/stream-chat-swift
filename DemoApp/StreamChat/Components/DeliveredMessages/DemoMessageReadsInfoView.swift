//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import StreamChatUI
import SwiftUI

struct DemoMessageReadsInfoView: View {
    let message: ChatMessage
    let channelController: ChatChannelController
    
    @Environment(\.dismiss) private var dismiss
    @State private var channel: ChatChannel?
    @State private var cancellables = Set<AnyCancellable>()
    
    init(message: ChatMessage, channelController: ChatChannelController) {
        self.message = message
        self.channelController = channelController
        self._channel = State(initialValue: channelController.channel)
    }
    
    var body: some View {
        NavigationView {
            List {
                if !deliveredUsers.isEmpty {
                    Section("Delivered") {
                        ForEach(deliveredUsers, id: \.id) { user in
                            UserReadInfoRow(
                                user: user,
                                status: .delivered
                            )
                        }
                    }
                }
                
                if !readUsers.isEmpty {
                    Section("Read") {
                        ForEach(readUsers, id: \.id) { user in
                            UserReadInfoRow(
                                user: user,
                                status: .read
                            )
                        }
                    }
                }
                
                if deliveredUsers.isEmpty && readUsers.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "eye.slash")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("No reads yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Message Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupChannelObserver()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var deliveredUsers: [ChatUser] {
        channel?.deliveredReads(for: message)
            .sorted {
                $0.lastDeliveredAt ?? Date.distantPast < $1.lastDeliveredAt ?? Date.distantPast
                    && $0.user.id < $1.user.id
            }
            .map(\.user) ?? []
    }
    
    private var readUsers: [ChatUser] {
        channel?.reads(for: message)
            .sorted {
                $0.lastReadAt < $1.lastReadAt
                    && $0.user.id < $1.user.id
            }
            .map(\.user) ?? []
    }
    
    // MARK: - Helper Methods
    
    private func setupChannelObserver() {
        channelController.channelChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { channelChange in
                switch channelChange {
                case .create(let newChannel), .update(let newChannel):
                    self.channel = newChannel
                case .remove:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func getDeliveredTimestamp(for user: ChatUser) -> Date? {
        channel?.reads
            .first { $0.user.id == user.id }
            .flatMap { $0.lastDeliveredAt }
    }
    
    private func getReadTimestamp(for user: ChatUser) -> Date? {
        channel?.reads
            .first { $0.user.id == user.id }
            .flatMap { $0.lastReadAt }
    }
}

// MARK: - User Read Info Row

struct UserReadInfoRow: View {
    let user: ChatUser
    let status: ReadStatus
    
    enum ReadStatus {
        case delivered
        case read
        
        var icon: String {
            switch self {
            case .delivered:
                return "checkmark"
            case .read:
                return "checkmark"
            }
        }
        
        var color: Color {
            switch self {
            case .delivered:
                return .gray
            case .read:
                return .blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            AsyncImage(url: user.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(user.name?.prefix(1).uppercased() ?? user.id)
                            .font(.headline)
                            .foregroundColor(.primary)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name ?? user.id)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Status Icon
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}
