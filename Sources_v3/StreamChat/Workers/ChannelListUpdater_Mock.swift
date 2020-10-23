//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelListUpdater
class ChannelListUpdaterMock<ExtraData: ExtraDataTypes>: ChannelListUpdater<ExtraData> {
    @Atomic var update_queries: [ChannelListQuery<ExtraData.Channel>] = []
    @Atomic var update_completion: ((Error?) -> Void)?
    
    @Atomic var markAllRead_completion: ((Error?) -> Void)?
    
    override func update(channelListQuery: ChannelListQuery<ExtraData.Channel>, completion: ((Error?) -> Void)? = nil) {
        _update_queries.mutate { $0.append(channelListQuery) }
        update_completion = completion
    }
    
    override func markAllRead(completion: ((Error?) -> Void)? = nil) {
        markAllRead_completion = completion
    }
}
