//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient

func createMemberInfoString(for channel: Channel) -> String {
    "\(channel.members.count) members, \(channel.members.filter(\.isOnline).count) online"
}

func createTypingMemberString(for channel: Channel) -> String? {
    guard !channel.currentlyTypingMembers.isEmpty else { return nil }
    let names = channel.currentlyTypingMembers.map { $0.name ?? $0.id }.sorted()
    return names.joined(separator: ",") + " \(names.count == 1 ? "is" : "are") typing..."
}
