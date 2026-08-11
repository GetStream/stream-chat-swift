//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MentionSuggestionsSearch_Tests: XCTestCase {
    // MARK: - searchUsers

    func test_searchUsers_whenInputEmpty_returnsAllUsers() {
        let users = [
            ChatUser.mock(id: "martin", name: "Martin"),
            ChatUser.mock(id: "marie", name: "Marie"),
            ChatUser.mock(id: "john", name: "John")
        ]

        let result = MentionSuggestionsSearch.searchUsers(users, by: "")

        XCTAssertEqual(Set(result.map(\.id)), ["martin", "marie", "john"])
    }

    func test_searchUsers_filtersByNameSubstring() {
        let users = [
            ChatUser.mock(id: "u1", name: "Martin"),
            ChatUser.mock(id: "u2", name: "Marie"),
            ChatUser.mock(id: "u3", name: "John")
        ]

        let result = MentionSuggestionsSearch.searchUsers(users, by: "mar")

        XCTAssertEqual(Set(result.map(\.id)), ["u1", "u2"])
    }

    func test_searchUsers_filtersByIdSubstring() {
        let users = [
            ChatUser.mock(id: "martin", name: "Anna"),
            ChatUser.mock(id: "john", name: "Bob")
        ]

        let result = MentionSuggestionsSearch.searchUsers(users, by: "martin")

        XCTAssertEqual(result.map(\.id), ["martin"])
    }

    func test_searchUsers_excludesGivenId() {
        let users = [
            ChatUser.mock(id: "me", name: "Martin"),
            ChatUser.mock(id: "other", name: "Marie")
        ]

        let result = MentionSuggestionsSearch.searchUsers(users, by: "mar", excludingId: "me")

        XCTAssertEqual(result.map(\.id), ["other"])
    }

    func test_searchUsers_isDiacriticInsensitive() {
        let users = [
            ChatUser.mock(id: "u1", name: "José"),
            ChatUser.mock(id: "u2", name: "Anna")
        ]

        let result = MentionSuggestionsSearch.searchUsers(users, by: "jose")

        XCTAssertEqual(result.map(\.id), ["u1"])
    }

    func test_searchUsers_sortsByLevenshteinDistance() {
        let users = [
            ChatUser.mock(id: "u1", name: "Johnny"),
            ChatUser.mock(id: "u2", name: "John")
        ]

        let result = MentionSuggestionsSearch.searchUsers(users, by: "John")

        XCTAssertEqual(result.map(\.id), ["u2", "u1"])
    }

    func test_searchUsers_deduplicatesUsers() {
        let user = ChatUser.mock(id: "martin", name: "Martin")

        let result = MentionSuggestionsSearch.searchUsers([user, user], by: "mar")

        XCTAssertEqual(result.map(\.id), ["martin"])
    }

    // MARK: - allAppUsersQuery

    func test_allAppUsersQuery_buildsAutocompleteFilterSortedByName() {
        let query = MentionSuggestionsSearch.allAppUsersQuery(for: "abc")

        XCTAssertEqual(
            query.filter,
            .or([
                .autocomplete(.name, text: "abc"),
                .autocomplete(.id, text: "abc")
            ])
        )
        XCTAssertEqual(query.sort, [.init(key: .name, isAscending: true)])
    }

    // MARK: - channelMembersQuery

    func test_channelMembersQuery_buildsAutocompleteNameFilterSortedByName() {
        let cid = ChannelId.unique
        let query = MentionSuggestionsSearch.channelMembersQuery(cid: cid, for: "abc")

        XCTAssertEqual(query.cid, cid)
        XCTAssertEqual(query.filter, .autocomplete(.name, text: "abc"))
        XCTAssertEqual(query.sort, [.init(key: .name, isAscending: true)])
    }

    // MARK: - requiresRemoteMemberSearch

    func test_requiresRemoteMemberSearch_whenMemberCountExceedsLastActiveMembers() {
        let channel = ChatChannel.mock(
            cid: .unique,
            lastActiveMembers: [.mock(id: "a"), .mock(id: "b")],
            memberCount: 1000
        )

        XCTAssertTrue(MentionSuggestionsSearch.requiresRemoteMemberSearch(for: channel))
    }

    func test_requiresRemoteMemberSearch_whenAllMembersAreLocal_returnsFalse() {
        let members: [ChatChannelMember] = [.mock(id: "a"), .mock(id: "b")]
        let channel = ChatChannel.mock(
            cid: .unique,
            lastActiveMembers: members,
            memberCount: members.count
        )

        XCTAssertFalse(MentionSuggestionsSearch.requiresRemoteMemberSearch(for: channel))
    }
}
