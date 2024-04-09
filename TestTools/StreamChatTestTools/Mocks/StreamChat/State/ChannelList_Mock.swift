//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

@available(iOS 13.0, *)
public class ChannelList_Mock: ChannelList {
    
    public static func mock(
        channels: [ChatChannel] = [],
        query: ChannelListQuery? = nil,
        client: ChatClient? = nil
    ) -> ChannelList_Mock {
        ChannelList_Mock(
            channels: channels,
            query: query ?? .init(filter: .nonEmpty),
            client: client ?? .mock(bundle: Bundle(for: Self.self))
        )
    }
    
    init(
        channels: [ChatChannel],
        query: ChannelListQuery,
        dynamicFilter: ((ChatChannel) -> Bool)? = nil,
        client: ChatClient,
        environment: ChannelList.Environment = .init()
    ) {
        let channelListUpdater = ChannelListUpdater(
            database: .init(kind: .inMemory, bundle: Bundle(for: Self.self)),
            apiClient: APIClient_Spy()
        )
        super.init(
            initialChannels: channels,
            query: query,
            dynamicFilter: dynamicFilter,
            channelListUpdater: channelListUpdater,
            client: client,
            environment: environment
        )
    }
    
    public func simulate(channels: [ChatChannel]) async throws {
        state.channels = StreamCollection(channels)
    }
    
    public var loadNextChannelsIsCalled = false
    public override func loadNextChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        loadNextChannelsIsCalled = true
        return Array(state.channels)
    }
}
