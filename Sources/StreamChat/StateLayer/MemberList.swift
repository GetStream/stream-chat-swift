//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannelMember` for the specified channel.
@available(iOS 13.0, *)
public final class MemberList {
    private let query: ChannelMemberListQuery
    private let memberListUpdater: ChannelMemberListUpdater
    
    init(query: ChannelMemberListQuery, client: ChatClient, environment: Environment = .init()) {
        self.query = query
        memberListUpdater = environment.memberListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        state = environment.stateBuilder(
            [],
            query,
            client.databaseContainer
        )
    }
    
    /// An observable object representing the current state of the member list.
    public let state: MemberListState
    
    /// Loads channel members for the specified pagination parameters and updates ``MemberListState/members``.
    ///
    /// - Parameter pagination: The pagination configuration which includes a limit and an offset or a cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channel members for the pagination.
    @discardableResult public func loadMembers(with pagination: Pagination) async throws -> [ChatChannelMember] {
        try await memberListUpdater.load(query.withPagination(pagination))
    }
    
    /// Loads more channel members and updates ``MemberListState/members``.
    ///
    /// - Parameters
    ///   - limit: The limit for the page size. The default limit is 30.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channel members.
    @discardableResult public func loadNextMembers(limit: Int? = nil) async throws -> [ChatChannelMember] {
        let pageSize = limit ?? Int.channelMembersPageSize
        let pagination = Pagination(pageSize: pageSize, offset: state.members.count)
        return try await loadMembers(with: pagination)
    }
}

@available(iOS 13.0, *)
extension MemberList {
    struct Environment {
        var memberListUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelMemberListUpdater = ChannelMemberListUpdater.init
        
        var stateBuilder: (
            _ members: [ChatChannelMember],
            _ query: ChannelMemberListQuery,
            _ database: DatabaseContainer
        ) -> MemberListState = MemberListState.init
    }
}

private extension ChannelMemberListQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var result = self
        result.pagination = pagination
        return result
    }
}
