//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChannelList_Mock: ChannelList, @unchecked Sendable {
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
        dynamicFilter: (@Sendable (ChatChannel) -> Bool)? = nil,
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
        state.channels = channels
    }

    @Atomic public var prefillGroups: [GroupedChannelsGroup] = []
    override public func prefill(group: GroupedChannelsGroup) async throws {
        _prefillGroups.mutate { $0.append(group) }
    }
    
    @Atomic public var refreshLoadedChannelsCallCount = 0
    @Atomic public var refreshLoadedChannelsResult: Result<Set<ChannelId>, Error> = .success([])
    override public func refreshLoadedChannels() async throws -> Set<ChannelId> {
        _refreshLoadedChannelsCallCount.mutate { $0 += 1 }
        return try refreshLoadedChannelsResult.get()
    }
    
    public var loadNextChannelsIsCalled = false
    override public func loadMoreChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        loadNextChannelsIsCalled = true
        return await MainActor.run {
            Array(state.channels)
        }
    }
}
