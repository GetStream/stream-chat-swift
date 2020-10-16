//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat

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
    if channel.isDirectMessage {
        return Array(channel.cachedMembers).first(where: { member in member.id != currentUserId })?.name ?? "Unnamed channel"
    } else {
        return channel.extraData.name ?? channel.cid.description
    }
}
