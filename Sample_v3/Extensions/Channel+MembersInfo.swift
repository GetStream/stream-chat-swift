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
