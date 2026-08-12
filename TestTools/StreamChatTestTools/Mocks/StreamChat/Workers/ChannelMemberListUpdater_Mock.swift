//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `ChannelMemberListUpdater`
final class ChannelMemberListUpdater_Mock: ChannelMemberListUpdater, @unchecked Sendable {
    @Atomic var load_query: ChannelMemberListQuery?
    @Atomic var load_queries: [ChannelMemberListQuery] = []
    @Atomic var load_completion: (@Sendable (Result<[ChatChannelMember], Error>) -> Void)?
    @Atomic var load_completions: [(@Sendable (Result<[ChatChannelMember], Error>) -> Void)] = []
    @Atomic var load_query_called: (ChannelMemberListQuery) -> Void = { _ in }
    @Atomic var load_completion_result: Result<[ChatChannelMember], Error>?

    func cleanUp() {
        load_query = nil
        load_queries.removeAll()
        load_completion = nil
        load_completions.removeAll()
        load_completion_result = nil
    }

    override func load(_ query: ChannelMemberListQuery, completion: (@Sendable (Result<[ChatChannelMember], Error>) -> Void)? = nil) {
        load_query = query
        _load_queries.mutate { $0.append(query) }
        load_query_called(query)
        if let completion {
            load_completion = completion
            _load_completions.mutate { $0.append(completion) }
            if let result = load_completion_result {
                completion(result)
            }
        }
    }
}
