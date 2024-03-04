//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct OrderedChannels {
    let orderedChannels: [ChatChannel]
    let query: ChannelListQuery
    let clientConfig: ChatClientConfig
    
    func withListChanges(_ changes: [ListChange<ChatChannel>]) -> [ChatChannel] {
        let sortDescriptors = ChannelDTO.channelListFetchRequest(query: query, chatClientConfig: clientConfig).sortDescriptors
        return orderedChannels.uniquelyApplied(changes, sortDescriptors: sortDescriptors ?? [])
    }
    
    func withInsertingPaginated(_ newSortedChannels: [ChatChannel]) -> [ChatChannel] {
        let sortDescriptors = ChannelDTO.channelListFetchRequest(query: query, chatClientConfig: clientConfig).sortDescriptors
        return orderedChannels.uniquelyMerged(newSortedChannels, sortDescriptors: sortDescriptors ?? [])
    }
}
