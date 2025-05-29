//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `ChannelMemberUpdater`
final class ChannelMemberUpdater_Mock: ChannelMemberUpdater, @unchecked Sendable {
    @Atomic var banMember_userId: UserId?
    @Atomic var banMember_cid: ChannelId?
    @Atomic var banMember_shadow: Bool?
    @Atomic var banMember_timeoutInMinutes: Int??
    @Atomic var banMember_reason: String??
    @Atomic var banMember_completion: ((Error?) -> Void)?
    @Atomic var banMember_completion_result: Result<Void, Error>?

    @Atomic var unbanMember_userId: UserId?
    @Atomic var unbanMember_cid: ChannelId?
    @Atomic var unbanMember_completion: ((Error?) -> Void)?
    @Atomic var unbanMember_completion_result: Result<Void, Error>?

    @Atomic var partialUpdate_userId: UserId?
    @Atomic var partialUpdate_cid: ChannelId?
    @Atomic var partialUpdate_updates: MemberUpdatePayload?
    @Atomic var partialUpdate_unset: [String]?
    @Atomic var partialUpdate_completion: ((Result<ChatChannelMember, Error>) -> Void)?
    @Atomic var partialUpdate_completion_result: Result<ChatChannelMember, Error>?

    func cleanUp() {
        banMember_userId = nil
        banMember_cid = nil
        banMember_shadow = nil
        banMember_timeoutInMinutes = nil
        banMember_reason = nil
        banMember_completion = nil
        banMember_completion_result = nil

        unbanMember_userId = nil
        unbanMember_cid = nil
        unbanMember_completion = nil
        unbanMember_completion_result = nil

        partialUpdate_userId = nil
        partialUpdate_cid = nil
        partialUpdate_updates = nil
        partialUpdate_unset = nil
        partialUpdate_completion = nil
        partialUpdate_completion_result = nil
    }

    override func banMember(
        _ userId: UserId,
        in cid: ChannelId,
        shadow: Bool,
        for timeoutInMinutes: Int? = nil,
        reason: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        banMember_userId = userId
        banMember_cid = cid
        banMember_shadow = shadow
        banMember_timeoutInMinutes = timeoutInMinutes
        banMember_reason = reason
        banMember_completion = completion
        banMember_completion_result?.invoke(with: completion)
    }

    override func unbanMember(
        _ userId: UserId,
        in cid: ChannelId, completion: ((Error?) -> Void)? = nil
    ) {
        unbanMember_userId = userId
        unbanMember_cid = cid
        unbanMember_completion = completion
        unbanMember_completion_result?.invoke(with: completion)
    }

    override func partialUpdate(
        userId: UserId,
        in cid: ChannelId,
        updates: MemberUpdatePayload?,
        unset: [String]?,
        completion: @escaping ((Result<ChatChannelMember, Error>) -> Void)
    ) {
        partialUpdate_userId = userId
        partialUpdate_cid = cid
        partialUpdate_updates = updates
        partialUpdate_unset = unset
        partialUpdate_completion = completion
        partialUpdate_completion_result?.invoke(with: completion)
    }
}
