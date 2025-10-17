//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat
import StreamChatUI

struct DemoMessageReadsInfoView: View {
    let message: ChatMessage
    let channel: ChatChannel
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if !deliveredUsers.isEmpty {
                    Section("Delivered") {
                        ForEach(deliveredUsers, id: \.id) { user in
                            UserReadInfoRow(
                                user: user,
                                status: .delivered,
                                timestamp: getDeliveredTimestamp(for: user)
                            )
                        }
                    }
                }
                
                if !readUsers.isEmpty {
                    Section("Read") {
                        ForEach(readUsers, id: \.id) { user in
                            UserReadInfoRow(
                                user: user,
                                status: .read,
                                timestamp: getReadTimestamp(for: user)
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
        }
    }
    
    // MARK: - Computed Properties
    
    private var deliveredUsers: [ChatUser] {
        channel.deliveredReads(for: message)
            .sorted { $0.lastDeliveredAt ?? Date.distantPast < $1.lastDeliveredAt ?? Date.distantPast }
            .map(\.user)
    }
    
    private var readUsers: [ChatUser] {
        channel.reads(for: message)
            .sorted { $0.lastReadAt < $1.lastReadAt }
            .map(\.user)
    }
    
    // MARK: - Helper Methods
    
    private func getDeliveredTimestamp(for user: ChatUser) -> Date? {
        channel.reads
            .first { $0.user.id == user.id }
            .flatMap { $0.lastDeliveredAt }
    }
    
    private func getReadTimestamp(for user: ChatUser) -> Date? {
        channel.reads
            .first { $0.user.id == user.id }
            .flatMap { $0.lastReadAt }
    }
}

// MARK: - User Read Info Row

struct UserReadInfoRow: View {
    let user: ChatUser
    let status: ReadStatus
    let timestamp: Date?
    
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
                
                if let timestamp = timestamp {
                    Text(formatTimestamp(timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status Icon
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}
