//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChannelList_Mock: ChannelList {
    
    public static func mock(
        query: ChannelListQuery? = nil,
        client: ChatClient? = nil
    ) -> ChannelList_Mock {
        ChannelList_Mock(
            query: query ?? .init(filter: .nonEmpty),
            client: client ?? .mock(bundle: Bundle(for: Self.self))
        )
    }
    
    override init(
        query: ChannelListQuery,
        dynamicFilter: ((ChatChannel) -> Bool)? = nil,
        client: ChatClient,
        environment: ChannelList.Environment = .init()
    ) {
        super.init(
            query: query,
            dynamicFilter: dynamicFilter,
            client: client,
            environment: environment
        )
    }
    
    @MainActor public func simulate(channels: [ChatChannel]) async throws {
        state.channels = StreamCollection(channels)
    }
    
    public var loadNextChannelsIsCalled = false
    public override func loadMoreChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        loadNextChannelsIsCalled = true
        return await MainActor.run {
            Array(state.channels)
        }
    }
}
