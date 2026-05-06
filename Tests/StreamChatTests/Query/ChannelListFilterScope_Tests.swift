//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<ChannelListFilterScope, T>

    func test_filterKeys_matchChannelCodingKeys() {
        // FilterKeys that exists in ChannelCodingKeys
        XCTAssertEqual(Key<ChannelId>.cid.rawValue, ChannelCodingKeys.cid.rawValue)
        XCTAssertEqual(Key<String>.id.rawValue, ChannelCodingKeys.id.rawValue)
        XCTAssertEqual(Key<String>.name.rawValue, ChannelCodingKeys.name.rawValue)
        XCTAssertEqual(Key<URL>.imageURL.rawValue, ChannelCodingKeys.imageURL.rawValue)
        XCTAssertEqual(Key<ChannelType>.type.rawValue, ChannelCodingKeys.typeRawValue.rawValue)
        XCTAssertEqual(Key<Date>.lastMessageAt.rawValue, ChannelCodingKeys.lastMessageAt.rawValue)
        XCTAssertEqual(Key<Date>.createdAt.rawValue, ChannelCodingKeys.createdAt.rawValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, ChannelCodingKeys.updatedAt.rawValue)
        XCTAssertEqual(Key<Date>.deletedAt.rawValue, ChannelCodingKeys.deletedAt.rawValue)
        XCTAssertEqual(Key<Bool>.disabled.rawValue, ChannelCodingKeys.disabled.rawValue)
        XCTAssertEqual(Key<Bool>.frozen.rawValue, ChannelCodingKeys.frozen.rawValue)
        XCTAssertEqual(Key<Int>.memberCount.rawValue, ChannelCodingKeys.memberCount.rawValue)
        XCTAssertEqual(Key<TeamId>.team.rawValue, ChannelCodingKeys.team.rawValue)
        XCTAssertEqual(Key<String>.filterTags.rawValue, ChannelCodingKeys.filterTags.rawValue)

        // FilterKeys without corresponding ChannelCodingKeys
        XCTAssertEqual(Key<UserId>.createdBy.rawValue, "created_by_id")
        XCTAssertEqual(Key<Bool>.joined.rawValue, "joined")
        XCTAssertEqual(Key<Bool>.muted.rawValue, "muted")
        XCTAssertEqual(Key<Bool>.pinned.rawValue, "pinned")
        XCTAssertEqual(Key<InviteFilterValue>.invite.rawValue, "invite")
        XCTAssertEqual(Key<String>.memberName.rawValue, "member.user.name")
        XCTAssertEqual(Key<Date>.lastUpdatedAt.rawValue, "last_updated")
        XCTAssertEqual(Key<Bool>.archived.rawValue, "archived")
    }

    func test_filterKeys_haveExpectedKeyPathValueMapper() {
        XCTAssertEqual(Key<ChannelId>.cid.keyPathString, "cid")
        XCTAssertEqual(Key<String>.id.keyPathString, "id")
        XCTAssertEqual(Key<String>.name.keyPathString, "name")
        XCTAssertEqual(Key<URL>.imageURL.keyPathString, "imageURL")
        XCTAssertEqual(Key<ChannelType>.type.keyPathString, "typeRawValue")
        XCTAssertEqual(Key<Date>.lastMessageAt.keyPathString, "lastMessageAt")
        XCTAssertEqual(Key<Date>.createdAt.keyPathString, "createdAt")
        XCTAssertEqual(Key<UserId>.createdBy.keyPathString, "createdBy.id")
        XCTAssertEqual(Key<Date>.updatedAt.keyPathString, "updatedAt")
        XCTAssertEqual(Key<Date>.deletedAt.keyPathString, "deletedAt")
        XCTAssertEqual(Key<Bool>.blocked.keyPathString, "isBlocked")
        XCTAssertEqual(Key<Bool>.hidden.keyPathString, "isHidden")
        XCTAssertEqual(Key<Bool>.disabled.keyPathString, "isDisabled")
        XCTAssertEqual(Key<Bool>.frozen.keyPathString, "isFrozen")
        XCTAssertEqual(Key<Int>.memberCount.keyPathString, "memberCount")
        XCTAssertEqual(Key<TeamId>.team.keyPathString, "team")
        XCTAssertEqual(Key<UserId>.members.keyPathString, "members.user.id")
        XCTAssertEqual(Key<String>.memberName.keyPathString, "members.user.name")
        XCTAssertEqual(Key<Date>.lastUpdatedAt.keyPathString, "defaultSortingAt")
        XCTAssertEqual(Key<Bool>.joined.keyPathString, "membership")
        XCTAssertEqual(Key<Bool>.muted.keyPathString, "mute")
        XCTAssertEqual(Key<Bool>.archived.keyPathString, "membership.archivedAt")
        XCTAssertEqual(Key<Bool>.pinned.keyPathString, "membership.pinnedAt")
        XCTAssertEqual(Key<String>.filterTags.keyPathString, "filterTags.name")
        XCTAssertNil(Key<InviteFilterValue>.invite.keyPathString)
    }

    func test_containMembersHelper() {
        // Check the `containMembers` helper translates to `members $in [ids]`
        let ids: [UserId] = [.unique, .unique]
        XCTAssertEqual(
            Filter<ChannelListFilterScope>.containMembers(userIds: ids),
            Filter<ChannelListFilterScope>.in(.members, values: ids)
        )
    }

    func test_noTeam_helper() {
        XCTAssertEqual(
            Filter<ChannelListFilterScope>.noTeam,
            Filter<ChannelListFilterScope>.equal(.team, to: nil)
        )
    }

    func test_hiddenFilter_valueIsDetected() {
        let hiddenValue = Bool.random()
        let testValues: [(Filter<ChannelListFilterScope>, Bool?)] = [
            (.equal(.hidden, to: hiddenValue), hiddenValue),
            (.containMembers(userIds: [.unique]), nil),
            (.autocomplete(.cid, text: .unique), nil),
            (.and([.exists(.imageURL), .autocomplete(.name, text: .unique)]), nil),
            (.and([.exists(.imageURL), .equal(.hidden, to: hiddenValue)]), hiddenValue),
            (.and([.exists(.imageURL), .or([.autocomplete(.name, text: .unique), .equal(.hidden, to: hiddenValue)])]), hiddenValue),
            (.and([.exists(.imageURL), .or([.autocomplete(.name, text: .unique), .equal(.frozen, to: true)])]), nil)
        ]

        for testValue in testValues {
            XCTAssertEqual(testValue.0.hiddenFilterValue, testValue.1, "\(testValue) failed")
        }
    }

    func test_debugDescription() {
        let id = "theid"
        let query = ChannelListQuery(
            filter: .containMembers(userIds: [id]),
            sort: [.init(key: .cid)],
            pageSize: 1,
            messagesLimit: 2,
            membersLimit: 3
        )

        XCTAssertEqual(query.debugDescription, "Filter: members IN [\"theid\"] | Sort: [cid:-1]")
    }

    func test_messageCount_filter_fallsBackToMessagesCountWhenStoredValueIsMissing() throws {
        let database = DatabaseContainer_Spy()

        // A: stored messageCount = 10, zero cached messages.
        let cidA = ChannelId.unique
        let channelA: ChannelPayload = .dummy(
            channel: .dummy(cid: cidA, messageCount: 10),
            messages: []
        )

        // B: backend omitted messageCount, 5 messages cached locally.
        let cidB = ChannelId.unique
        let messagesB = (0..<5).map { _ in MessagePayload.dummy(messageId: .unique, authorUserId: .unique) }
        let channelB: ChannelPayload = .dummy(
            channel: .dummy(cid: cidB, messageCount: nil),
            messages: messagesB
        )

        // C: stored messageCount = 0, zero cached messages.
        let cidC = ChannelId.unique
        let channelC: ChannelPayload = .dummy(
            channel: .dummy(cid: cidC, messageCount: 0),
            messages: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelA, query: nil, cache: nil)
            try session.saveChannel(payload: channelB, query: nil, cache: nil)
            try session.saveChannel(payload: channelC, query: nil, cache: nil)
        }

        // `> 3` matches A via stored branch (10) and B via messages.@count branch (5).
        let greaterPredicate = try XCTUnwrap(
            Filter<ChannelListFilterScope>.greater(.messageCount, than: 3).predicate
        )
        let greaterRequest = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        greaterRequest.predicate = greaterPredicate
        let greaterResult = try database.viewContext.fetch(greaterRequest)
        XCTAssertEqual(Set(greaterResult.map(\.cid)), [cidA.rawValue, cidB.rawValue])

        // `== 5` matches only B (stored for A is 10; stored for B is nil so we fall back to messages.@count = 5).
        let equalPredicate = try XCTUnwrap(
            Filter<ChannelListFilterScope>.equal(.messageCount, to: 5).predicate
        )
        let equalRequest = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        equalRequest.predicate = equalPredicate
        let equalResult = try database.viewContext.fetch(equalRequest)
        XCTAssertEqual(Set(equalResult.map(\.cid)), [cidB.rawValue])
    }

    func test_messageCount_filter_usesMessagesCountAfterEventWhenStoredValueIsMissing() throws {
        let database = DatabaseContainer_Spy()
        let cid = ChannelId.unique

        let channel: ChannelPayload = .dummy(
            channel: .dummy(cid: cid, messageCount: nil),
            messages: []
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channel, query: nil, cache: nil)
        }

        let newMessage: MessagePayload = .dummy(
            messageId: .unique,
            authorUserId: .unique
        )
        let newMessageEvent = EventPayload(
            eventType: .messageNew,
            cid: cid,
            channel: channel.channel,
            message: newMessage
        )
        try database.writeSynchronously { session in
            try session.saveEvent(payload: newMessageEvent)
        }

        let storedChannel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertNil(storedChannel.messageCount)

        let lessOrEqualPredicate = try XCTUnwrap(
            Filter<ChannelListFilterScope>.lessOrEqual(.messageCount, than: 1).predicate
        )
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.predicate = lessOrEqualPredicate
        let result = try database.viewContext.fetch(request)
        XCTAssertEqual(Set(result.map(\.cid)), [cid.rawValue])
    }
}
