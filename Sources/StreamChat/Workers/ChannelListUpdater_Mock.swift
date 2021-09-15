//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelListUpdater
class ChannelListUpdaterMock: ChannelListUpdater {
    @Atomic var fetch_channelListQueries: [ChannelListQuery] = []
    @Atomic var fetch_completions: [(Result<ChannelListPayload, Error>) -> Void] = []
    
    @Atomic var update_queries: [ChannelListQuery] = []
    @Atomic var update_completion: ((Result<ChannelListPayload, Error>) -> Void)? = nil
    
    @Atomic var markAllRead_completion: ((Error?) -> Void)?
    
    func cleanUp() {
        fetch_channelListQueries.removeAll()
        fetch_completions.removeAll()
        
        update_queries.removeAll()
        update_completion = nil
        
        markAllRead_completion = nil
    }
    
    override func fetch(
        _ channelListQuery: ChannelListQuery,
        completion: @escaping (Result<ChannelListPayload, Error>) -> Void
    ) {
        _fetch_channelListQueries.mutate { $0.append(channelListQuery) }
        _fetch_completions.mutate { $0.append(completion) }
    }
    
    override func update(
        channelListQuery: ChannelListQuery,
        completion: ((Result<ChannelListPayload, Error>) -> Void)? = nil
    ) {
        _update_queries.mutate { $0.append(channelListQuery) }
        update_completion = completion
    }
    
    override func markAllRead(completion: ((Error?) -> Void)? = nil) {
        markAllRead_completion = completion
    }
}
