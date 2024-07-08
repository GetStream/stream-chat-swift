//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannelMember` for the specified channel.
public final class MemberList {
    private let query: ChannelMemberListQuery
    private let memberListUpdater: ChannelMemberListUpdater
    private let stateBuilder: StateBuilder<MemberListState>
    
    init(query: ChannelMemberListQuery, client: ChatClient, environment: Environment = .init()) {
        self.query = query
        memberListUpdater = environment.memberListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        stateBuilder = StateBuilder {
            environment.stateBuilder(
                query,
                client.databaseContainer
            )
        }
    }
    
    // MARK: - Accessing the State
    
    /// An observable object representing the current state of the member list.
    @MainActor public lazy var state: MemberListState = stateBuilder.build()
    
    /// Fetches the most recent state from the server and updates the local store.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func get() async throws {
        let pagination = Pagination(pageSize: query.pagination.pageSize)
        try await loadMembers(with: pagination)
    }
    
    // MARK: - Member Pagination
    
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
    @discardableResult public func loadMoreMembers(limit: Int? = nil) async throws -> [ChatChannelMember] {
        let pageSize = limit ?? query.pagination.pageSize
        let pagination = Pagination(pageSize: pageSize, offset: await state.members.count)
        return try await loadMembers(with: pagination)
    }
}

extension MemberList {
    struct Environment {
        var memberListUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelMemberListUpdater = ChannelMemberListUpdater.init
        
        var stateBuilder: @MainActor(
            _ query: ChannelMemberListQuery,
            _ database: DatabaseContainer
        ) -> MemberListState = { @MainActor in
            MemberListState(query: $0, database: $1)
        }
    }
}

private extension ChannelMemberListQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var result = self
        result.pagination = pagination
        return result
    }
}
