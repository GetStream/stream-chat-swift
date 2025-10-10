//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `ChannelMemberListUpdater`
final class ChannelMemberListUpdater_Mock: ChannelMemberListUpdater, @unchecked Sendable {
    @Atomic var load_query: ChannelMemberListQuery?
    @Atomic var load_completion: (@Sendable (Result<[ChatChannelMember], Error>) -> Void)?

    func cleanUp() {
        load_query = nil
        load_completion = nil
    }

    override func load(_ query: ChannelMemberListQuery, completion: (@Sendable (Result<[ChatChannelMember], Error>) -> Void)? = nil) {
        load_query = query
        load_completion = completion
    }
}
