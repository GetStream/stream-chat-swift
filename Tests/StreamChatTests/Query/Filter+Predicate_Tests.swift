//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class Filter_Predicate_Tests: XCTestCase {
    func test_filterProduceTheRightPredicate() {
        // ChannelListFilterScope
        assertPredicate(Filter<ChannelListFilterScope>.containMembers(userIds: ["12", "34"]), "ANY members.user.id == \"12\" AND ANY members.user.id == \"34\"")
        assertPredicate(Filter<ChannelListFilterScope>.nonEmpty, "lastMessageAt > CAST(-978307200.000000, \"NSDate\")")
        assertPredicate(Filter<ChannelListFilterScope>.noTeam, "team == <null>")

        // MessageSearchFilterScope
        XCTAssertNil(Filter<MessageSearchFilterScope>.queryText("hello").predicate)
        assertPredicate(Filter<MessageSearchFilterScope>.withAttachments([.file]), "ANY attachments.type == file")
        assertPredicate(Filter<MessageSearchFilterScope>.withAttachments, "attachments != nil")
        assertPredicate(Filter<MessageSearchFilterScope>.withoutAttachments, "attachments == nil")

        // UserListFilterScope
        assertPredicate(Filter<UserListFilterScope>.equal(.createdAt, to: Date(timeIntervalSince1970: 0)), "userCreatedAt == CAST(-978307200.000000, \"NSDate\")")

        // Basic Filter operators
        assertPredicate(Filter<ChannelListFilterScope>.equal(.id, to: "123"), "id == \"123\"")
        assertPredicate(Filter<ChannelListFilterScope>.notEqual(.hidden, to: true), "isHidden != 1")
        assertPredicate(Filter<ChannelListFilterScope>.greater(.memberCount, than: 2), "memberCount > 2")
        assertPredicate(Filter<ChannelListFilterScope>.greaterOrEqual(.memberCount, than: 4), "memberCount >= 4")
        assertPredicate(Filter<ChannelListFilterScope>.less(.memberCount, than: 3), "memberCount < 3")
        assertPredicate(Filter<ChannelListFilterScope>.lessOrEqual(.memberCount, than: 53), "memberCount <= 53")
        assertPredicate(Filter<ChannelListFilterScope>.in(.members, values: ["12", "34"]), "ANY members.user.id == \"12\" AND ANY members.user.id == \"34\"")
        assertPredicate(Filter<ChannelListFilterScope>.notIn(.members, values: ["33", "44"]), "NOT ANY members.user.id IN {\"33\", \"44\"}")
        XCTAssertNil(Filter<ChannelListFilterScope>.query(.name, text: "Hi").predicate)
        assertPredicate(Filter<ChannelListFilterScope>.autocomplete(.name, text: "Hi"), "name BEGINSWITH[cd] \"Hi\"")
        assertPredicate(Filter<ChannelListFilterScope>.exists(.hidden), "isHidden != nil")
        assertPredicate(Filter<ChannelListFilterScope>.exists(.hidden, exists: false), "isHidden == nil")
        #warning("Correct?")
        assertPredicate(Filter<ChannelListFilterScope>.contains(.members, value: "44"), "members.user.id IN \"44\"")

        // Filter and / or / nor
        assertPredicate(Filter<ChannelListFilterScope>.and([
            .equal(.name, to: "Hi"),
            .in(.members, values: ["12", "34"]),
            .exists(.hidden)
        ]), "name == \"Hi\" AND (ANY members.user.id == \"12\" AND ANY members.user.id == \"34\") AND isHidden != nil")
        assertPredicate(Filter<ChannelListFilterScope>.or([
            .equal(.name, to: "Hi"),
            .in(.members, values: ["12", "34"]),
            .exists(.hidden)
        ]), "name == \"Hi\" OR (ANY members.user.id == \"12\" AND ANY members.user.id == \"34\") OR isHidden != nil")
        assertPredicate(Filter<ChannelListFilterScope>.nor([
            .equal(.name, to: "Hi"),
            .exists(.hidden)
        ]), "(NOT name == \"Hi\") AND (NOT isHidden != nil)")
    }

    func test_channelListPredicateResults() throws {
        let database = DatabaseContainer_Spy()

        func assert(
            _ queryFilter: Filter<ChannelListFilterScope>,
            ids: [String],
            predicate: String,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
            request.predicate = queryFilter.predicate
            let objects = NSManagedObject.load(by: request, context: database.viewContext)

            let sortedReceivedIds = objects.map(\.cid).sorted()
            let sortedExpectedIds = ids.sorted()
            XCTAssertEqual(sortedExpectedIds, sortedReceivedIds, file: file, line: line)
            assertPredicate(queryFilter, predicate, file: file, line: line)
        }

        let channel1 = ChannelPayload.dummy(
            channel: .dummy(
                cid: .init(type: .team, id: "c1")
            ),
            members: [.dummy(user: .dummy(userId: "12")), .dummy(user: .dummy(userId: "34"))]
        )

        let channel2 = ChannelPayload.dummy(
            channel: .dummy(
                cid: .init(type: .team, id: "c2"),
                name: "C2Hello",
                lastMessageAt: Date()
            ),
            members: [.dummy(user: .dummy(userId: "34"))]
        )

        let channel3 = ChannelPayload.dummy(
            channel: .dummy(
                cid: .init(type: .team, id: "c3"),
                team: "Team3"
            ),
            members: [.dummy(user: .dummy(userId: "12"))]
        )

        let channel4 = ChannelPayload.dummy(
            channel: .dummy(
                cid: .init(type: .team, id: "c4"),
                team: "Teame"
            ),
            members: [.dummy(user: .dummy(userId: "12")), .dummy(user: .dummy(userId: "56"))]
        )

        try database.writeSynchronously { session in
            try [channel1, channel2, channel3, channel4].forEach {
                try session.saveChannel(payload: $0)
            }
        }

        // Things don't work as expected
        // https://stackoverflow.com/questions/14471910/nspredicate-aggregate-operations-with-none
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.predicate = NSPredicate(format: "NONE members.user.id == \"12\"")
//        request.predicate = NSPredicate(format: "cid IN %@", ["team:c1", "team:c2"])
        let objects = NSManagedObject.load(by: request, context: database.viewContext)
        let sortedReceivedIds = objects.map(\.cid).sorted()
        let sortedExpectedIds = ["team:c1"].sorted()
        XCTAssertEqual(sortedExpectedIds, sortedReceivedIds)

        assert(
            Filter<ChannelListFilterScope>.containMembers(userIds: ["12", "34"]),
            ids: ["team:c1"],
            predicate: "ANY members.user.id == \"12\" AND ANY members.user.id == \"34\""
        )
        assert(
            Filter<ChannelListFilterScope>.containMembers(userIds: ["12"]),
            ids: ["team:c1", "team:c3"],
            predicate: "ANY members.user.id == \"12\" AND ANY members.user.id == \"34\""
        )
        assert(
            Filter<ChannelListFilterScope>.nonEmpty,
            ids: ["team:c2"],
            predicate: "lastMessageAt > CAST(-978307200.000000, \"NSDate\")"
        )
        assert(
            Filter<ChannelListFilterScope>.noTeam,
            ids: ["team:c1", "team:c2"],
            predicate: "team == <null>"
        )
        assert(
            Filter<ChannelListFilterScope>.equal(.cid, to: ChannelId(type: .team, id: "c1")),
            ids: ["team:c1"],
            predicate: "cid == team:c1"
        )
        assert(
            Filter<ChannelListFilterScope>.notEqual(.name, to: "C2Hello"),
            ids: ["team:c1", "team:c3"],
            predicate: "name != \"C2Hello\""
        )
        assert(
            Filter<ChannelListFilterScope>.greater(.lastMessageAt, than: Date(timeIntervalSince1970: 0)),
            ids: ["team:c2"],
            predicate: "lastMessageAt > CAST(-978307200.000000, \"NSDate\")"
        )
        assert(
            Filter<ChannelListFilterScope>.greaterOrEqual(.memberCount, than: 10),
            ids: [],
            predicate: "memberCount >= 10"
        )
        assert(
            Filter<ChannelListFilterScope>.less(.memberCount, than: 2),
            ids: ["team:c1", "team:c2", "team:c3"],
            predicate: "memberCount < 2"
        )
        assert(
            Filter<ChannelListFilterScope>.lessOrEqual(.memberCount, than: 1),
            ids: ["team:c1", "team:c2", "team:c3"],
            predicate: "memberCount <= 1"
        )
        assert(
            Filter<ChannelListFilterScope>.in(.members, values: ["12"]),
            ids: ["team:c1", "team:c3"],
            predicate: "ANY members.user.id == \"12\""
        )
        assert(
            Filter<ChannelListFilterScope>.in(.members, values: ["34"]),
            ids: ["team:c1", "team:c2"],
            predicate: "ANY members.user.id == \"34\""
        )
        assert(
            Filter<ChannelListFilterScope>.notIn(.members, values: ["12"]),
            ids: ["team:c2"],
            predicate: "NOT ANY members.user.id IN {\"12\"}"
        )
        assert(
            Filter<ChannelListFilterScope>.query(.team, text: "112"),
            ids: ["team:c1", "team:c2", "team:c3"],
            predicate: ""
        ) // Query's predicate returns nil
        assert(
            Filter<ChannelListFilterScope>.autocomplete(.cid, text: "Téam"),
            ids: ["team:c1", "team:c2", "team:c3"],
            predicate: ""
        )
        assert(
            Filter<ChannelListFilterScope>.exists(.lastMessageAt),
            ids: ["team:c1", "team:c2", "team:c3"],
            predicate: ""
        )
        assert(
            Filter<ChannelListFilterScope>.exists(.lastMessageAt, exists: false),
            ids: ["team:c1", "team:c2", "team:c3"],
            predicate: ""
        )
//        assert(Filter<ChannelListFilterScope>.contains(.team, value: "Team3"),
//               ids: ["team:c1", "team:c2", "team:c3"],
//               predicate: "")
    }

    func test_correctFilterPayloadKeys() {
        // AnyChannelListFilterScope
        checkChannelListPayloadKey(.members, "members")
        checkChannelListPayloadKey(.cid, "cid")
        checkChannelListPayloadKey(.id, "id")
        checkChannelListPayloadKey(.name, "name")
        checkChannelListPayloadKey(.imageURL, "image")
        checkChannelListPayloadKey(.type, "type")
        checkChannelListPayloadKey(.lastMessageAt, "last_message_at")
        checkChannelListPayloadKey(.createdBy, "created_by_id")
        checkChannelListPayloadKey(.createdAt, "created_at")
        checkChannelListPayloadKey(.updatedAt, "updated_at")
        checkChannelListPayloadKey(.deletedAt, "deleted_at")
        checkChannelListPayloadKey(.hidden, "hidden")
        checkChannelListPayloadKey(.frozen, "frozen")
        checkChannelListPayloadKey(.memberCount, "member_count")
        checkChannelListPayloadKey(.team, "team")
        checkChannelListPayloadKey(.joined, "joined")
        checkChannelListPayloadKey(.muted, "muted")
        checkChannelListPayloadKey(.invite, "invite")
        checkChannelListPayloadKey(.memberName, "member.user.name")
        checkChannelListPayloadKey(.lastUpdatedAt, "last_updated")

        // AnyUserListFilterScope
        checkUserPayloadKey(.id, "id")
        checkUserPayloadKey(.name, "name")
        checkUserPayloadKey(.imageURL, "image")
        checkUserPayloadKey(.role, "role")
        checkUserPayloadKey(.isOnline, "online")
        checkUserPayloadKey(.isBanned, "banned")
        checkUserPayloadKey(.createdAt, "created_at")
        checkUserPayloadKey(.updatedAt, "updated_at")
        checkUserPayloadKey(.lastActiveAt, "last_active")
        checkUserPayloadKey(.isInvisible, "invisible")
        checkUserPayloadKey(.unreadChannelsCount, "unread_channels")
        checkUserPayloadKey(.unreadMessagesCount, "total_unread_count")
        checkUserPayloadKey(.isAnonymous, "anon")
        checkUserPayloadKey(.teams, "teams")

        // AnyMessageSearchFilterScope
        checkMessagePayloadKey(.text, "text")
        checkMessagePayloadKey(.authorId, "user.id")
        checkMessagePayloadKey(.hasAttachmentsOfType, "attachments.type")

        // AnyMemberListFilterScope
        checkMemberPayloadKey(.isModerator, "is_moderator")
        checkMemberPayloadKey(.id, "id")
        checkMemberPayloadKey(.name, "name")
        checkMemberPayloadKey(.banned, "banned")
        checkMemberPayloadKey(.invite, "invite")
        checkMemberPayloadKey(.joined, "joined")
        checkMemberPayloadKey(.createdAt, "created_at")
        checkMemberPayloadKey(.updatedAt, "updated_at")
        checkMemberPayloadKey(.lastActiveAt, "last_active")
    }

    func test_correctFilterDTOKeys() {
        // AnyChannelListFilterScope
        checkChannelListDTOKey(.members, "members.user.id")
        checkChannelListDTOKey(.cid, "cid")
        checkChannelListDTOKey(.name, "name")
        checkChannelListDTOKey(.imageURL, "imageURL")
        checkChannelListDTOKey(.type, "typeRawValue")
        checkChannelListDTOKey(.lastMessageAt, "lastMessageAt")
        checkChannelListDTOKey(.createdBy, "createdBy.id")
        checkChannelListDTOKey(.createdAt, "createdAt")
        checkChannelListDTOKey(.updatedAt, "updatedAt")
        checkChannelListDTOKey(.deletedAt, "deletedAt")
        checkChannelListDTOKey(.hidden, "isHidden")
        checkChannelListDTOKey(.frozen, "isFrozen")
        checkChannelListDTOKey(.memberCount, "memberCount")
        checkChannelListDTOKey(.team, "team")
        // AnyChannelListFilterScope - No DTO key
        checkChannelListDTOKey(.id, "id")
        checkChannelListDTOKey(.joined, "joined")
        checkChannelListDTOKey(.muted, "muted")
        checkChannelListDTOKey(.invite, "invite")
        checkChannelListDTOKey(.memberName, "member.user.name")
        checkChannelListDTOKey(.lastUpdatedAt, "last_updated")

        // AnyUserListFilterScope
        checkUserDTOKey(.id, "id")
        checkUserDTOKey(.name, "name")
        checkUserDTOKey(.imageURL, "imageURL")
        checkUserDTOKey(.role, "userRoleRaw")
        checkUserDTOKey(.isOnline, "isOnline")
        checkUserDTOKey(.isBanned, "isBanned")
        checkUserDTOKey(.createdAt, "userCreatedAt")
        checkUserDTOKey(.updatedAt, "userUpdatedAt")
        checkUserDTOKey(.lastActiveAt, "lastActivityAt")
        checkUserDTOKey(.isInvisible, "currentUser.isInvisible")
        checkUserDTOKey(.unreadChannelsCount, "currentUser.unreadChannelsCount")
        checkUserDTOKey(.unreadMessagesCount, "currentUser.unreadMessagesCount")
        checkUserDTOKey(.teams, "teams")
        // AnyUserListFilterScope - No DTO key
        checkUserDTOKey(.isAnonymous, "anon")

        // AnyMessageSearchFilterScope
        checkMessageDTOKey(.text, "text")
        checkMessageDTOKey(.authorId, "user.id")
        checkMessageDTOKey(.hasAttachmentsOfType, "attachments.type")

        // AnyMemberListFilterScope
        checkMemberDTOKey(.isModerator, "is_moderator")
        checkMemberDTOKey(.id, "id")
        checkMemberDTOKey(.banned, "isBanned")
        checkMemberDTOKey(.createdAt, "memberCreatedAt")
        checkMemberDTOKey(.updatedAt, "memberUpdatedAt")
        // AnyMemberListFilterScope - No DTO key
        checkMemberDTOKey(.name, "name")
        checkMemberDTOKey(.invite, "invite")
        checkMemberDTOKey(.joined, "joined")
        checkMemberDTOKey(.lastActiveAt, "last_active")
    }

    private func checkChannelListPayloadKey<V: Encodable>(
        _ filterKey: FilterKey<ChannelListFilterScope, V>,
        _ stringKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checkPayloadKey(filterKey, stringKey, ChannelListFilterScope.self, file: file, line: line)
    }

    private func checkUserPayloadKey<V: Encodable>(
        _ filterKey: FilterKey<UserListFilterScope, V>,
        _ stringKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checkPayloadKey(filterKey, stringKey, UserListFilterScope.self, file: file, line: line)
    }

    private func checkMessagePayloadKey<V: Encodable>(
        _ filterKey: FilterKey<MessageSearchFilterScope, V>,
        _ stringKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checkPayloadKey(filterKey, stringKey, MessageSearchFilterScope.self, file: file, line: line)
    }

    private func checkMemberPayloadKey<V: Encodable>(
        _ filterKey: FilterKey<MemberListFilterScope, V>,
        _ stringKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checkPayloadKey(filterKey, stringKey, MemberListFilterScope.self, file: file, line: line)
    }

    private func checkPayloadKey<S: FilterScope, V: Encodable>(
        _ filterKey: FilterKey<S, V>,
        _ stringKey: String,
        _ scopeType: S.Type,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let key = filterKey.rawValue
        XCTAssertEqual(key, stringKey, file: file, line: line)
    }

    private func checkChannelListDTOKey<V: Encodable>(
        _ filterKey: FilterKey<ChannelListFilterScope, V>,
        _ stringKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checkDTOKey(filterKey, stringKey, ChannelListFilterScope.self, file: file, line: line)
    }

    private func checkUserDTOKey<V: Encodable>(
        _ filterKey: FilterKey<UserListFilterScope, V>,
        _ stringKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checkDTOKey(filterKey, stringKey, UserListFilterScope.self, file: file, line: line)
    }

    private func checkMessageDTOKey<V: Encodable>(
        _ filterKey: FilterKey<MessageSearchFilterScope, V>,
        _ stringKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checkDTOKey(filterKey, stringKey, MessageSearchFilterScope.self, file: file, line: line)
    }

    private func checkMemberDTOKey<V: Encodable>(
        _ filterKey: FilterKey<MemberListFilterScope, V>,
        _ stringKey: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        checkDTOKey(filterKey, stringKey, MemberListFilterScope.self, file: file, line: line)
    }

    private func checkDTOKey<S: FilterScope, V: Encodable>(
        _ filterKey: FilterKey<S, V>,
        _ stringKey: String,
        _ scopeType: S.Type,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let key = filterKey.autoKey?.dtoKey else {
            XCTFail("No DTO Key", file: file, line: line)
            return
        }
        XCTAssertEqual(key, stringKey, file: file, line: line)
    }

    private func assertPredicate<T: FilterScope>(
        _ filter: Filter<T>,
        _ stringFormat: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let predicate = filter.predicate else {
            XCTFail("No predicate", file: file, line: line)
            return
        }

        XCTAssertEqual(stringFormat, predicate.predicateFormat, file: file, line: line)
    }
}
