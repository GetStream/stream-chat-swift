//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelListUpdater
class ChannelListUpdaterMock: ChannelListUpdater {
    @Atomic var update_queries: [ChannelListQuery] = []
    @Atomic var update_completion: ((Result<ChannelListPayload, Error>) -> Void)? = nil
    
    @Atomic var markAllRead_completion: ((Error?) -> Void)?
    
    func cleanUp() {
        update_queries.removeAll()
        update_completion = nil
        
        markAllRead_completion = nil
    }
    
    override func update(
        channelListQuery: ChannelListQuery,
        trumpExistingChannels: Bool = false,
        completion: ((Result<ChannelListPayload, Error>) -> Void)? = nil
    ) {
        _update_queries.mutate { $0.append(channelListQuery) }
        update_completion = completion
    }
    
    override func markAllRead(completion: ((Error?) -> Void)? = nil) {
        markAllRead_completion = completion
    }
}
