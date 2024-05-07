//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension ChannelMemberListUpdater {
    func load(_ query: ChannelMemberListQuery) async throws -> [ChatChannelMember] {
        try await withCheckedThrowingContinuation { continuation in
            load(query) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func member(with userId: UserId, cid: ChannelId) async throws -> ChatChannelMember {
        let members = try await load(.channelMember(userId: userId, cid: cid))
        guard let member = members.first else { throw ClientError.MemberDoesNotExist(userId: userId, cid: cid) }
        return member
    }
}
