//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `ChannelMemberListUpdater`
final class ChannelMemberListUpdaterMock<ExtraData: ExtraDataTypes>: ChannelMemberListUpdater<ExtraData> {
    @Atomic var load_query: ChannelMemberListQuery<ExtraData.User>?
    @Atomic var load_completion: ((Error?) -> Void)?

    override func load(_ query: ChannelMemberListQuery<ExtraData.User>, completion: ((Error?) -> Void)? = nil) {
        load_query = query
        load_completion = completion
    }
}
