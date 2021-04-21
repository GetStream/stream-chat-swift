//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `ChannelMemberListUpdater`
final class ChannelMemberListUpdaterMock<ExtraData: ExtraDataTypes>: ChannelMemberListUpdater<ExtraData> {
    @Atomic var load_query: _ChannelMemberListQuery<ExtraData.User>?
    @Atomic var load_completion: ((Error?) -> Void)?
    
    func cleanUp() {
        load_query = nil
        load_completion = nil
    }

    override func load(_ query: _ChannelMemberListQuery<ExtraData.User>, completion: ((Error?) -> Void)? = nil) {
        load_query = query
        load_completion = completion
    }
}
