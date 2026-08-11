//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DefaultMentionSuggestionsProvider_Tests: XCTestCase {
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

    func test_mentionSuggestions_returnsMatchingChannelUsers() async throws {
        let provider = DefaultMentionSuggestionsProvider(client: client)
        let channel = ChatChannel.mock(
            cid: .unique,
            lastActiveMembers: [
                .mock(id: "martin", name: "Martin"),
                .mock(id: "marie", name: "Marie"),
                .mock(id: "john", name: "John")
            ]
        )

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "mar", channel: channel)
        )

        XCTAssertEqual(Set(userIds(from: suggestions)), ["martin", "marie"])
    }

    func test_mentionSuggestions_includesWatchersAndMembers() async throws {
        let provider = DefaultMentionSuggestionsProvider(client: client)
        let channel = ChatChannel.mock(
            cid: .unique,
            lastActiveMembers: [.mock(id: "member", name: "Member")],
            lastActiveWatchers: [.mock(id: "watcher", name: "Watcher")]
        )

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "", channel: channel)
        )

        XCTAssertEqual(Set(userIds(from: suggestions)), ["member", "watcher"])
    }

    func test_mentionSuggestions_excludesCurrentUser() async throws {
        client.currentUserId_mock = "me"
        let provider = DefaultMentionSuggestionsProvider(client: client)
        let channel = ChatChannel.mock(
            cid: .unique,
            lastActiveMembers: [
                .mock(id: "me", name: "Me"),
                .mock(id: "other", name: "Other")
            ]
        )

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "", channel: channel)
        )

        XCTAssertEqual(userIds(from: suggestions), ["other"])
    }

    func test_mentionSuggestions_whenMentionAllAppUsers_searchesAllAppUsers() async throws {
        let provider = DefaultMentionSuggestionsProvider(client: client, mentionAllAppUsers: true)
        let response: Result<UserListPayload, Error> = .success(.init(users: []))
        client.mockAPIClient.test_mockResponseResult(response)
        let channel = ChatChannel.mock(
            cid: .unique,
            lastActiveMembers: [.mock(id: "martin", name: "Martin")]
        )

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "mar", channel: channel)
        )

        // The query is sent to the API (all app users) instead of filtering the
        // channel's local members.
        XCTAssertEqual(client.mockAPIClient.request_endpoint?.path.value, EndpointPath.users.value)
        XCTAssertTrue(suggestions.isEmpty)
    }

    func test_mentionSuggestions_onlyReturnsUserSuggestions() async throws {
        let provider = DefaultMentionSuggestionsProvider(client: client)
        let channel = ChatChannel.mock(
            cid: .unique,
            lastActiveMembers: [.mock(id: "martin", name: "Martin")]
        )

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "", channel: channel)
        )

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.kind is MentionSuggestion.User })
    }

    func test_mentionSuggestions_whenLargeChannel_searchesMembersRemotely() async throws {
        let cid = ChannelId.unique
        try client.mockDatabaseContainer.createChannel(cid: cid, withMessages: false)

        let remoteMember = ChannelMemberResponse.dummy(
            user: .dummy(userId: "remote-user", name: "Remote User")
        )
        let response: Result<MembersResponse, Error> = .success(.dummy(members: [remoteMember]))
        client.mockAPIClient.test_mockResponseResult(response)

        let provider = DefaultMentionSuggestionsProvider(client: client)
        let channel = ChatChannel.mock(
            cid: cid,
            lastActiveMembers: [.mock(id: "local-only", name: "Local")],
            memberCount: 1000
        )

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "Rem", channel: channel)
        )

        XCTAssertEqual(client.mockAPIClient.request_endpoint?.path.value, "/api/v2/chat/members")
        XCTAssertEqual(userIds(from: suggestions), ["remote-user"])
    }

    func test_mentionSuggestions_whenLargeChannelAndEmptyText_returnsNoUsers() async throws {
        let provider = DefaultMentionSuggestionsProvider(client: client)
        let channel = ChatChannel.mock(
            cid: .unique,
            lastActiveMembers: [.mock(id: "local-only", name: "Local")],
            memberCount: 1000
        )

        let suggestions = try await provider.mentionSuggestions(
            for: MentionSuggestionsRequest(text: "", channel: channel)
        )

        XCTAssertNil(client.mockAPIClient.request_endpoint)
        XCTAssertTrue(suggestions.isEmpty)
    }

    // MARK: - private

    private func userIds(from suggestions: [MentionSuggestion]) -> [String] {
        suggestions.compactMap { ($0.kind as? MentionSuggestion.User)?.user.id }
    }
}
