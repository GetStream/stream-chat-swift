//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EnhancedMentionSuggestionsProvider_Tests: XCTestCase {
    private var client: ChatClient_Mock!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock
    }

    override func tearDown() {
        client.cleanUp()
        client = nil
        super.tearDown()
    }

    func test_mentionSuggestions_whenEmptyText_returnsBroadcastsAndDoesNotFetchRolesAndGroups() async throws {
        client.mockRolesRepository.searchRoles_completion_result = .success([Role(name: "admin")])
        client.mockUserGroupsRepository.searchUserGroups_completion_result = .success([makeGroup(id: "g1")])
        let provider = makeProvider(config: .enhanced)

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "", channel: makeChannel())
        )

        // Broadcasts come first, on a bare `@`.
        XCTAssertEqual(Array(suggestions.map(\.type).prefix(2)), [.channel, .here])
        // Roles and groups are not fetched for an empty query.
        XCTAssertNil(client.mockRolesRepository.searchRoles_query)
        XCTAssertNil(client.mockUserGroupsRepository.searchUserGroups_query)
        XCTAssertFalse(suggestions.contains { $0.type == .role || $0.type == .group })
    }

    func test_mentionSuggestions_whenText_returnsBroadcastRolesGroupsAndUsers() async throws {
        client.mockRolesRepository.searchRoles_completion_result = .success([Role(name: "admin")])
        client.mockUserGroupsRepository.searchUserGroups_completion_result = .success([makeGroup(id: "g1")])
        let provider = makeProvider(config: .enhanced)

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "ch", channel: makeChannel())
        )

        // `@channel` matches the prefix, `@here` does not.
        XCTAssertEqual(suggestions.map(\.type), [.channel, .role, .group])
        XCTAssertEqual(roleNames(from: suggestions), ["admin"])
        XCTAssertEqual(groupIds(from: suggestions), ["g1"])
        XCTAssertEqual(client.mockRolesRepository.searchRoles_query?.query, "ch")
        XCTAssertEqual(client.mockUserGroupsRepository.searchUserGroups_query?.query, "ch")
    }

    func test_mentionSuggestions_whenTextMatchesHere_returnsHereBroadcastOnly() async throws {
        client.mockRolesRepository.searchRoles_completion_result = .success([])
        client.mockUserGroupsRepository.searchUserGroups_completion_result = .success([])
        let provider = makeProvider(config: .enhanced)

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "he", channel: makeChannel())
        )

        XCTAssertTrue(suggestions.contains { $0.type == .here })
        XCTAssertFalse(suggestions.contains { $0.type == .channel })
    }

    func test_mentionSuggestions_whenHereNotAllowed_doesNotSuggestHere() async throws {
        let provider = makeProvider(config: .init(allowedMentionTypes: [.channel, .user]))

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "", channel: makeChannel())
        )

        XCTAssertTrue(suggestions.contains { $0.type == .channel })
        XCTAssertFalse(suggestions.contains { $0.type == .here })
    }

    func test_mentionSuggestions_whenUserOnlyConfig_doesNotFetchOrSuggestOtherTypes() async throws {
        let provider = makeProvider(config: .init(allowedMentionTypes: [.user]))

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "ch", channel: makeChannel())
        )

        XCTAssertTrue(suggestions.allSatisfy { $0.type == .user })
        XCTAssertNil(client.mockRolesRepository.searchRoles_query)
        XCTAssertNil(client.mockUserGroupsRepository.searchUserGroups_query)
    }

    func test_mentionSuggestions_whenRolesAndGroupsRequestsFail_stillReturnsBroadcasts() async throws {
        client.mockRolesRepository.searchRoles_completion_result = .failure(TestError())
        client.mockUserGroupsRepository.searchUserGroups_completion_result = .failure(TestError())
        let provider = makeProvider(config: .enhanced)

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "ch", channel: makeChannel())
        )

        XCTAssertEqual(suggestions.map(\.type), [.channel])
    }

    // MARK: - private

    private func makeProvider(config: MentionSuggestionsConfig) -> EnhancedMentionSuggestionsProvider {
        EnhancedMentionSuggestionsProvider(client: client, config: config)
    }

    private func makeChannel() -> ChatChannel {
        ChatChannel.mock(
            cid: .unique,
            lastActiveMembers: [
                .mock(id: "martin", name: "Martin"),
                .mock(id: "john", name: "John")
            ]
        )
    }

    private func makeGroup(id: String) -> UserGroup {
        UserGroup(id: id, name: "Group \(id)", createdAt: .init(), updatedAt: .init())
    }

    private func roleNames(from suggestions: [MentionSuggestion]) -> [String] {
        suggestions.compactMap { ($0.kind as? MentionSuggestion.Role)?.role.name }
    }

    private func groupIds(from suggestions: [MentionSuggestion]) -> [String] {
        suggestions.compactMap { ($0.kind as? MentionSuggestion.Group)?.group.id }
    }
}
