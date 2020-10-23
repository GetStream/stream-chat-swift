//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `ChannelMemberUpdater`
final class ChannelMemberUpdaterMock: ChannelMemberUpdater {
    @Atomic var banMember_userId: UserId?
    @Atomic var banMember_cid: ChannelId?
    @Atomic var banMember_timeoutInMinutes: Int??
    @Atomic var banMember_reason: String??
    @Atomic var banMember_completion: ((Error?) -> Void)?
    
    @Atomic var unbanMember_userId: UserId?
    @Atomic var unbanMember_cid: ChannelId?
    @Atomic var unbanMember_completion: ((Error?) -> Void)?

    override func banMember(
        _ userId: UserId,
        in cid: ChannelId,
        for timeoutInMinutes: Int? = nil,
        reason: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        banMember_userId = userId
        banMember_cid = cid
        banMember_timeoutInMinutes = timeoutInMinutes
        banMember_reason = reason
        banMember_completion = completion
    }
    
    override func unbanMember(
        _ userId: UserId,
        in cid: ChannelId, completion: ((Error?) -> Void)? = nil
    ) {
        unbanMember_userId = userId
        unbanMember_cid = cid
        unbanMember_completion = completion
    }
}
