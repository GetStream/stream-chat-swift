//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelListUpdater
class ChannelListUpdaterMock<ExtraData: ExtraDataTypes>: ChannelListUpdater<ExtraData> {
    @Atomic var update_queries: [_ChannelListQuery<ExtraData.Channel>] = []
    @Atomic var update_completion: ((Error?) -> Void)?
    
    @Atomic var markAllRead_completion: ((Error?) -> Void)?
    
    func cleanUp() {
        update_queries.removeAll()
        update_completion = nil
        
        markAllRead_completion = nil
    }
    
    override func update(channelListQuery: _ChannelListQuery<ExtraData.Channel>, completion: ((Error?) -> Void)? = nil) {
        _update_queries.mutate { $0.append(channelListQuery) }
        update_completion = completion
    }
    
    override func markAllRead(completion: ((Error?) -> Void)? = nil) {
        markAllRead_completion = completion
    }
}
