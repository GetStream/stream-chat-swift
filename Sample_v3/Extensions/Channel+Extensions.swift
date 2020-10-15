//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient

/// Creates formatted string for channel members and online members.
///
/// Example result: ` "10 members, 3 online"`
func createMemberInfoString(for channel: ChatChannel) -> String {
    "\(channel.memberCount) members, \(channel.watcherCount) online"
}

/// Creates formatted string for currently typing members from `currentlyTypingMembers` property of `ChatChannel` if any.
///
/// Example result: ` "Nick is typing..."` or`"Nick, Maria are typing..."`
func createTypingMemberString(for channel: ChatChannel?) -> String? {
    guard let members = channel?.currentlyTypingMembers, !members.isEmpty else { return nil }
    let names = members.map { $0.name ?? $0.id }.sorted()
    return names.joined(separator: ", ") + " \(names.count == 1 ? "is" : "are") typing..."
}

/// Creates title for channel. If it is direct message chat it will return users name.
///
/// Example result: `"Joe Biden"`
func createChannelTitle(for channel: ChatChannel?, _ currentUserId: UserId?) -> String {
    guard let channel = channel, let currentUserId = currentUserId else { return "Unnamed channel" }
    let channelName = channel.extraData.name ?? channel.cid.description
    if channel.isDirectMessage {
        let otherMember = Array(channel.cachedMembers).first(where: { member in member.id != currentUserId })
        let otherMemberName = otherMember?.name ?? ""
        // Naming priority for a DM:
        // 1. other member's name
        // 2. other member's id
        // 3. channel name
        // 4. channel id
        return (otherMember != nil ? (otherMemberName.isEmpty ? otherMember!.id : otherMemberName) : channelName)
    } else {
        // Naming priority for a channel:
        // 1. channel name
        // 2. channel id
        return channelName
    }
}
