//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

/// Mock implementation of ChannelListUpdater
class ChannelListUpdaterMock<ExtraData: ExtraDataTypes>: ChannelListUpdater<ExtraData> {
    @Atomic var update_query: ChannelListQuery?
    @Atomic var update_calls_counter = 0
    @Atomic var update_completion: ((Error?) -> Void)?
    
    @Atomic var markAllRead_completion: ((Error?) -> Void)?
    
    override func update(channelListQuery: ChannelListQuery, completion: ((Error?) -> Void)? = nil) {
        update_query = channelListQuery
        update_completion = completion
        _update_calls_counter.mutate { $0 += 1 }
    }
    
    override func markAllRead(completion: ((Error?) -> Void)? = nil) {
        markAllRead_completion = completion
    }
}
