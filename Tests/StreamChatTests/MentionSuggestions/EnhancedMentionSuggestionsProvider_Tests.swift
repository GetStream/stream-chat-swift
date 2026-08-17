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
        client.mockRolesRepository.searchRoles_completion_result = .success([Role.dummy(name: "admin")])
        client.mockUserGroupsRepository.searchUserGroups_completion_result = .success([makeGroup(id: "g1")])
        let provider = makeProvider()

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "", channel: makeChannel())
        )

        // Broadcasts come first, on a bare `@`.
        XCTAssertTrue(suggestions[0].kind is MentionSuggestion.Channel)
        XCTAssertTrue(suggestions[1].kind is MentionSuggestion.Here)
        // Roles and groups are not fetched for an empty query.
        XCTAssertNil(client.mockRolesRepository.searchRoles_query)
        XCTAssertNil(client.mockUserGroupsRepository.searchUserGroups_query)
        XCTAssertFalse(suggestions.contains { $0.kind is MentionSuggestion.Role || $0.kind is MentionSuggestion.Group })
    }

    func test_mentionSuggestions_whenText_returnsBroadcastRolesGroupsAndUsers() async throws {
        client.mockRolesRepository.searchRoles_completion_result = .success([Role.dummy(name: "admin")])
        client.mockUserGroupsRepository.searchUserGroups_completion_result = .success([makeGroup(id: "g1")])
        let provider = makeProvider()

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "ch", channel: makeChannel())
        )

        // `@channel` matches the prefix, `@here` does not.
        XCTAssertTrue(suggestions[0].kind is MentionSuggestion.Channel)
        XCTAssertTrue(suggestions[1].kind is MentionSuggestion.Role)
        XCTAssertTrue(suggestions[2].kind is MentionSuggestion.Group)
        XCTAssertEqual(roleNames(from: suggestions), ["admin"])
        XCTAssertEqual(groupIds(from: suggestions), ["g1"])
        XCTAssertEqual(client.mockRolesRepository.searchRoles_query?.query, "ch")
        XCTAssertEqual(client.mockUserGroupsRepository.searchUserGroups_query?.query, "ch")
    }

    func test_mentionSuggestions_whenTextMatchesHere_returnsHereBroadcastOnly() async throws {
        client.mockRolesRepository.searchRoles_completion_result = .success([])
        client.mockUserGroupsRepository.searchUserGroups_completion_result = .success([])
        let provider = makeProvider()

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "he", channel: makeChannel())
        )

        XCTAssertTrue(suggestions.contains { $0.kind is MentionSuggestion.Here })
        XCTAssertFalse(suggestions.contains { $0.kind is MentionSuggestion.Channel })
    }

    func test_mentionSuggestions_whenHereNotAllowedByChannel_doesNotSuggestHere() async throws {
        let provider = makeProvider()

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "", channel: makeChannel(capabilities: [.notifyChannel]))
        )

        XCTAssertTrue(suggestions.contains { $0.kind is MentionSuggestion.Channel })
        XCTAssertFalse(suggestions.contains { $0.kind is MentionSuggestion.Here })
    }

    func test_mentionSuggestions_whenChannelHasNoNotifyCapabilities_doesNotFetchOrSuggestOtherTypes() async throws {
        let provider = makeProvider()

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "ch", channel: makeChannel(capabilities: []))
        )

        XCTAssertTrue(suggestions.allSatisfy { $0.kind is MentionSuggestion.User })
        XCTAssertNil(client.mockRolesRepository.searchRoles_query)
        XCTAssertNil(client.mockUserGroupsRepository.searchUserGroups_query)
    }

    func test_mentionSuggestions_whenRolesAndGroupsRequestsFail_stillReturnsBroadcasts() async throws {
        client.mockRolesRepository.searchRoles_completion_result = .failure(TestError())
        client.mockUserGroupsRepository.searchUserGroups_completion_result = .failure(TestError())
        let provider = makeProvider()

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "ch", channel: makeChannel())
        )

        XCTAssertEqual(suggestions.count, 1)
        XCTAssertTrue(suggestions[0].kind is MentionSuggestion.Channel)
    }

    func test_mentionSuggestions_whenLargeChannel_searchesMembersRemotely() async throws {
        client.mockRolesRepository.searchRoles_completion_result = .success([])
        client.mockUserGroupsRepository.searchUserGroups_completion_result = .success([])

        let cid = ChannelId.unique
        try client.mockDatabaseContainer.createChannel(cid: cid, withMessages: false)

        let remoteMember = ChannelMemberResponse.dummy(
            user: .dummy(userId: "remote-user", name: "Remote User")
        )
        let response: Result<MembersResponse, Error> = .success(.dummy(members: [remoteMember]))
        client.mockAPIClient.test_mockResponseResult(response)

        let provider = makeProvider()
        let channel = makeChannel(
            cid: cid,
            capabilities: [],
            lastActiveMembers: [.mock(id: "local-only", name: "Local")],
            memberCount: 1000
        )

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "Rem", channel: channel)
        )

        XCTAssertEqual(client.mockAPIClient.request_endpoint?.path.value, "/api/v2/chat/members")
        XCTAssertEqual(userIds(from: suggestions), ["remote-user"])
    }

    func test_mentionSuggestions_whenLargeChannelAndEmptyText_returnsBroadcastsWithoutFetchingMembers() async throws {
        let provider = makeProvider()
        let channel = makeChannel(
            lastActiveMembers: [.mock(id: "local-only", name: "Local")],
            memberCount: 1000
        )

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "", channel: channel)
        )

        XCTAssertNil(client.mockAPIClient.request_endpoint)
        XCTAssertTrue(suggestions.contains { $0.kind is MentionSuggestion.Channel })
        XCTAssertTrue(suggestions.contains { $0.kind is MentionSuggestion.Here })
        XCTAssertFalse(suggestions.contains { $0.kind is MentionSuggestion.User })
    }

    // MARK: - private

    private func makeProvider(mentionAllAppUsers: Bool = false) -> EnhancedMentionSuggestionsProvider {
        EnhancedMentionSuggestionsProvider(client: client, mentionAllAppUsers: mentionAllAppUsers)
    }

    private func makeChannel(
        cid: ChannelId = .unique,
        capabilities: Set<ChannelCapability> = [.notifyHere, .notifyChannel, .notifyRole, .notifyGroup],
        lastActiveMembers: [ChatChannelMember] = [
            .mock(id: "martin", name: "Martin"),
            .mock(id: "john", name: "John")
        ],
        memberCount: Int = 0
    ) -> ChatChannel {
        ChatChannel.mock(
            cid: cid,
            ownCapabilities: capabilities,
            lastActiveMembers: lastActiveMembers,
            memberCount: memberCount
        )
    }

    private func userIds(from suggestions: [MentionSuggestion]) -> [String] {
        suggestions.compactMap { ($0.kind as? MentionSuggestion.User)?.user.id }
    }

    private func makeGroup(id: String) -> UserGroup {
        UserGroup.dummy(id: id, name: "Group \(id)")
    }

    private func roleNames(from suggestions: [MentionSuggestion]) -> [String] {
        suggestions.compactMap { ($0.kind as? MentionSuggestion.Role)?.role.name }
    }

    private func groupIds(from suggestions: [MentionSuggestion]) -> [String] {
        suggestions.compactMap { ($0.kind as? MentionSuggestion.Group)?.group.id }
    }
}
