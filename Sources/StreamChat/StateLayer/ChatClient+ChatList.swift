//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Factory Methods for Creating Chat Lists

@available(iOS 13.0, *)
extension ChatClient {
    /// Creates an instance of ``ChatList`` which represents an array of channels matching to the specified ``ChannelListQuery``.
    ///
    /// Matching channels are stored in ``ChatListState.channels``. Use pagination methods in ``ChatList`` for loading more matching channels to the observable state.
    /// Refer to [querying channels in Stream documentation](https://getstream.io/chat/docs/ios-swift/query_channels/?language=swift) for additional details.
    ///
    /// - Note: Only channels that the user can read are returned, therefore, make sure that the query uses a filter that includes such logic. It is recommended to include a members filter which includes the currently logged in user (e.g. `.containMembers(userIds: ["thierry"])`).
    ///
    /// - Parameters:
    ///   - query: The query specifies which channels are part of the list and how channels are sorted.
    ///   - dynamicFilter: A filter block for filtering by channel's extra data fields or as a manual filter when ``ChatClientConfig.isChannelAutomaticFilteringEnabled`` is false ([read more](https://getstream.io/chat/docs/sdk/ios/client/controllers/channels/)).
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of ``ChatList`` which represents actions and the current state of the list.
    public func makeChatList(with query: ChannelListQuery, dynamicFilter: ((ChatChannel) -> Bool)? = nil) async throws -> ChatList {
        let channels = try await channelListUpdater.update(channelListQuery: query)
        let list = ChatList(channels: channels, query: query, dynamicFilter: dynamicFilter, channelListUpdater: channelListUpdater, client: self)
        let state = list.state
        syncRepository.trackChannelListQuery { [weak state] in state?.query }
        return list
    }
}
