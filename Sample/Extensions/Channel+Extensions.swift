//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

/// Creates formatted string for channel members and online members.
///
/// Example result: ` "10 members, 3 online"`
func createMemberInfoString(for channel: ChatChannel) -> String {
    "\(channel.memberCount) members, \(channel.watcherCount) online"
}

/// Creates formatted string for currently typing users from `currentlyTypingUsers` property of `ChatChannel` if any.
///
/// Example result: ` "Nick is typing..."` or`"Nick, Maria are typing..."`
func createTypingUserString(for channel: ChatChannel?) -> String? {
    guard let users = channel?.currentlyTypingUsers, !users.isEmpty else { return nil }
    let names = users.map { $0.name ?? $0.id }.sorted()
    return names.joined(separator: ", ") + " \(names.count == 1 ? "is" : "are") typing..."
}

/// Creates title for channel. If it is direct message chat it will return users name.
///
/// Example result: `"Luke Skywalker"`
func createChannelTitle(for channel: ChatChannel?, _ currentUserId: UserId?) -> String {
    guard let channel = channel, let currentUserId = currentUserId else { return "Unnamed channel" }
    let channelName = channel.name ?? channel.cid.description
    if channel.isDirectMessageChannel {
        let otherMember = Array(channel.lastActiveMembers).first(where: { member in member.id != currentUserId })
        // Naming priority for a DM:
        // 1. other member's name
        // 2. other member's id
        // 3. channel name
        // 4. channel id
        if let otherMember = otherMember {
            if let otherMemberName = otherMember.name, !otherMemberName.isEmpty {
                return otherMemberName
            } else {
                return otherMember.id
            }
        } else {
            return channelName
        }
    } else {
        // Naming priority for a channel:
        // 1. channel name
        // 2. channel id
        return channelName
    }
}
