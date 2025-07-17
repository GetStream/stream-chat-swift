//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadDTO_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        database = nil

        super.tearDown()
    }

    func test_saveThreadListPayload() throws {
        let payload = ThreadListPayload(
            threads: [
                dummyThreadPayload(),
                dummyThreadPayload()
            ],
            next: nil
        )

        let dto = database.viewContext.saveThreadList(
            payload: payload
        )

        XCTAssertEqual(dto.count, 2)
    }

    func test_saveThreadPayload() throws {
        let payload = ThreadPayload(
            parentMessageId: .unique,
            parentMessage: .dummy(),
            channel: .dummy(),
            createdBy: .dummy(userId: .unique),
            replyCount: 10,
            participantCount: 10,
            activeParticipantCount: 2,
            threadParticipants: [dummyThreadParticipantPayload()],
            lastMessageAt: .unique,
            createdAt: .unique,
            updatedAt: .unique,
            title: "Test",
            latestReplies: [.dummy(), .dummy()],
            read: [dummyThreadReadPayload()],
            draft: nil,
            extraData: [:]
        )

        let dto = try database.viewContext.saveThread(
            payload: payload,
            cache: nil
        )

        XCTAssertEqual(dto.title, "Test")
        XCTAssertEqual(dto.replyCount, 10)
        XCTAssertEqual(dto.participantCount, 10)
        XCTAssertEqual(dto.threadParticipants.count, 1)
        XCTAssertEqual(dto.activeParticipantCount, 2)
        XCTAssertEqual(dto.latestReplies.count, 2)
        XCTAssertEqual(dto.read.count, 1)
        XCTAssertEqual(dto.parentMessageId, payload.parentMessageId)
        XCTAssertEqual(dto.parentMessage.id, payload.parentMessage.id)
        XCTAssertEqual(dto.channel.cid, payload.channel.cid.rawValue)
        XCTAssertEqual(dto.createdBy.id, payload.createdBy.id)
        XCTAssertEqual(dto.lastMessageAt, payload.lastMessageAt?.bridgeDate)
        XCTAssertEqual(dto.createdAt, payload.createdAt.bridgeDate)
        XCTAssertEqual(dto.updatedAt, payload.updatedAt?.bridgeDate)
    }

    func test_asModel() throws {
        let payload = ThreadPayload(
            parentMessageId: .unique,
            parentMessage: .dummy(),
            channel: .dummy(),
            createdBy: .dummy(userId: .unique),
            replyCount: 10,
            participantCount: 10,
            activeParticipantCount: 2,
            threadParticipants: [dummyThreadParticipantPayload()],
            lastMessageAt: .unique,
            createdAt: .unique,
            updatedAt: .unique,
            title: "Test",
            latestReplies: [.dummy(), .dummy()],
            read: [dummyThreadReadPayload()],
            draft: nil,
            extraData: [:]
        )

        let dto = try database.viewContext.saveThread(
            payload: payload,
            cache: nil
        )

        let model = try dto.asModel()
        
        XCTAssertEqual(model.title, "Test")
        XCTAssertEqual(model.replyCount, 10)
        XCTAssertEqual(model.participantCount, 10)
        XCTAssertEqual(model.activeParticipantCount, 2)
        XCTAssertEqual(model.threadParticipants.count, 1)
        XCTAssertEqual(model.latestReplies.count, 2)
        XCTAssertEqual(model.reads.count, 1)
        XCTAssertEqual(model.parentMessageId, payload.parentMessageId)
        XCTAssertEqual(model.parentMessage.id, payload.parentMessage.id)
        XCTAssertEqual(model.channel.cid, payload.channel.cid)
        XCTAssertEqual(model.createdBy.id, payload.createdBy.id)
        XCTAssertEqual(model.lastMessageAt, payload.lastMessageAt)
        XCTAssertEqual(model.createdAt, payload.createdAt)
        XCTAssertEqual(model.updatedAt, payload.updatedAt)
    }

    func test_asModel_sortsLatestRepliesByCreatedAt() throws {
        let now = Date()
        let payload = ThreadPayload.dummy(
            parentMessageId: .unique,
            latestReplies: [
                .dummy(text: "3", createdAt: now.addingTimeInterval(20)),
                .dummy(text: "2", createdAt: now.addingTimeInterval(10)),
                .dummy(text: "1", createdAt: now)
            ]
        )

        let dto = try database.viewContext.saveThread(
            payload: payload,
            cache: nil
        )

        let model = try dto.asModel()

        XCTAssertEqual(
            model.latestReplies.map(\.text),
            ["1", "2", "3"]
        )
    }

    func test_saveThreadPayload_withDraftReply() throws {
        // GIVEN
        let draftMessagePayload = DraftMessagePayload(
            id: .unique,
            text: "Draft reply text",
            command: nil,
            args: nil,
            showReplyInChannel: false,
            mentionedUsers: nil,
            extraData: [:],
            attachments: nil,
            isSilent: false
        )

        let draftPayload = DraftPayload(
            cid: .unique,
            channelPayload: nil,
            createdAt: .init(),
            message: draftMessagePayload,
            quotedMessage: nil,
            parentId: nil,
            parentMessage: nil
        )

        let payload = ThreadPayload(
            parentMessageId: .unique,
            parentMessage: .dummy(),
            channel: .dummy(),
            createdBy: .dummy(userId: .unique),
            replyCount: 10,
            participantCount: 10,
            activeParticipantCount: 2,
            threadParticipants: [dummyThreadParticipantPayload()],
            lastMessageAt: .unique,
            createdAt: .unique,
            updatedAt: .unique,
            title: "Test",
            latestReplies: [.dummy(), .dummy()],
            read: [dummyThreadReadPayload()],
            draft: draftPayload,
            extraData: [:]
        )

        _ = try database.viewContext.saveCurrentUser(payload: .dummy(userId: .unique, role: .admin))

        // WHEN
        let dto = try database.viewContext.saveThread(
            payload: payload,
            cache: nil
        )

        // THEN
        XCTAssertEqual(dto.parentMessage.draftReply?.text, "Draft reply text")
        XCTAssertTrue(dto.parentMessage.draftReply?.isDraft ?? false)
        XCTAssertEqual(dto.parentMessage.draftReply?.type, MessageType.regular.rawValue)

        // Verify the draft reply is included in the model
        let model = try dto.asModel()
        XCTAssertEqual(model.parentMessage.draftReply?.text, "Draft reply text")
    }

    func test_saveThreadPayload_whenDraftIsNil_removesExistingDraft() throws {
        // GIVEN
        // First save a thread with a draft
        let draftMessagePayload = DraftMessagePayload(
            id: .unique,
            text: "Draft reply text",
            command: nil,
            args: nil,
            showReplyInChannel: false,
            mentionedUsers: nil,
            extraData: [:],
            attachments: nil,
            isSilent: false
        )

        let draftPayload = DraftPayload(
            cid: .unique,
            channelPayload: nil,
            createdAt: .init(),
            message: draftMessagePayload,
            quotedMessage: nil,
            parentId: nil,
            parentMessage: nil
        )

        let payloadWithDraft = ThreadPayload(
            parentMessageId: .unique,
            parentMessage: .dummy(),
            channel: .dummy(),
            createdBy: .dummy(userId: .unique),
            replyCount: 10,
            participantCount: 10,
            activeParticipantCount: 2,
            threadParticipants: [dummyThreadParticipantPayload()],
            lastMessageAt: .unique,
            createdAt: .unique,
            updatedAt: .unique,
            title: "Test",
            latestReplies: [.dummy(), .dummy()],
            read: [dummyThreadReadPayload()],
            draft: draftPayload,
            extraData: [:]
        )

        _ = try database.viewContext.saveCurrentUser(payload: .dummy(userId: .unique, role: .admin))

        let dto = try database.viewContext.saveThread(
            payload: payloadWithDraft,
            cache: nil
        )

        // Verify draft exists
        XCTAssertNotNil(dto.parentMessage.draftReply)

        // WHEN
        // Save the same thread without a draft
        let payloadWithoutDraft = ThreadPayload(
            parentMessageId: payloadWithDraft.parentMessageId,
            parentMessage: payloadWithDraft.parentMessage,
            channel: payloadWithDraft.channel,
            createdBy: payloadWithDraft.createdBy,
            replyCount: payloadWithDraft.replyCount,
            participantCount: payloadWithDraft.participantCount,
            activeParticipantCount: 2,
            threadParticipants: payloadWithDraft.threadParticipants,
            lastMessageAt: payloadWithDraft.lastMessageAt,
            createdAt: payloadWithDraft.createdAt,
            updatedAt: payloadWithDraft.updatedAt,
            title: payloadWithDraft.title,
            latestReplies: payloadWithDraft.latestReplies,
            read: payloadWithDraft.read,
            draft: nil,
            extraData: payloadWithDraft.extraData
        )

        let updatedDto = try database.viewContext.saveThread(
            payload: payloadWithoutDraft,
            cache: nil
        )

        // THEN
        XCTAssertNil(updatedDto.parentMessage.draftReply)
        let model = try updatedDto.asModel()
        XCTAssertNil(model.parentMessage.draftReply)
    }

    func test_threadListSortingKey() {
        let encoder = JSONEncoder.stream

        var threadListSortingKey = ThreadListSortingKey.createdAt
        XCTAssertEqual(encoder.encodedString(threadListSortingKey), "created_at")
        XCTAssertEqual(
            threadListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(keyPath: \ThreadDTO.createdAt, ascending: true)
        )
        XCTAssertEqual(
            threadListSortingKey.sortDescriptor(isAscending: false),
            NSSortDescriptor(keyPath: \ThreadDTO.createdAt, ascending: false)
        )

        threadListSortingKey = .updatedAt
        XCTAssertEqual(encoder.encodedString(threadListSortingKey), "updated_at")
        XCTAssertEqual(
            threadListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(keyPath: \ThreadDTO.updatedAt, ascending: true)
        )

        threadListSortingKey = .lastMessageAt
        XCTAssertEqual(encoder.encodedString(threadListSortingKey), "last_message_at")
        XCTAssertEqual(
            threadListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(keyPath: \ThreadDTO.lastMessageAt, ascending: true)
        )

        threadListSortingKey = .participantCount
        XCTAssertEqual(encoder.encodedString(threadListSortingKey), "participant_count")
        XCTAssertEqual(
            threadListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(keyPath: \ThreadDTO.participantCount, ascending: true)
        )

        threadListSortingKey = .replyCount
        XCTAssertEqual(encoder.encodedString(threadListSortingKey), "reply_count")
        XCTAssertEqual(
            threadListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(keyPath: \ThreadDTO.replyCount, ascending: true)
        )

        threadListSortingKey = .parentMessageId
        XCTAssertEqual(encoder.encodedString(threadListSortingKey), "parent_message_id")
        XCTAssertEqual(
            threadListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(keyPath: \ThreadDTO.parentMessageId, ascending: true)
        )

        threadListSortingKey = .hasUnread
        XCTAssertEqual(encoder.encodedString(threadListSortingKey), "has_unread")
        XCTAssertEqual(
            threadListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(keyPath: \ThreadDTO.currentUserUnreadCount, ascending: true)
        )
    }

    func test_threadListQuery_withFilteringAndSorting() throws {
        // Create two thread queries with different sortings.
        let cid = ChannelId.unique
        let filter: Filter<ThreadListFilterScope> = .equal(.cid, to: cid.rawValue)
        let queryWithDefaultSorting = ThreadListQuery(watch: true, filter: filter)
        let queryWithUpdatedAtSorting = ThreadListQuery(
            watch: true,
            filter: filter,
            sort: [.init(key: .updatedAt, isAscending: false)]
        )

        // Create dummy thread payloads with different timestamps
        let now = Date()
        let payload1 = dummyThreadPayload(
            parentMessageId: .unique,
            channel: .dummy(cid: cid),
            lastMessageAt: now.addingTimeInterval(-300), // 5 minutes ago
            updatedAt: now.addingTimeInterval(-100)       // 1 minute 40s ago
        )
        let payload2 = dummyThreadPayload(
            parentMessageId: .unique,
            channel: .dummy(cid: cid),
            lastMessageAt: now.addingTimeInterval(-200), // 3 minutes 20s ago
            updatedAt: now.addingTimeInterval(-50)        // 50s ago
        )
        let payload3 = dummyThreadPayload(
            parentMessageId: .unique,
            channel: .dummy(cid: cid),
            lastMessageAt: now.addingTimeInterval(-100), // 1 minute 40s ago
            updatedAt: now.addingTimeInterval(-200)       // 3 minutes 20s ago
        )
        let payload4 = dummyThreadPayload(
            parentMessageId: .unique,
            channel: .dummy(cid: cid),
            lastMessageAt: now.addingTimeInterval(-50),  // 50s ago
            updatedAt: now.addingTimeInterval(-300)       // 5 minutes ago
        )

        // Save the threads to DB. It doesn't matter which query we use because the filter for both of them is the same.
        try database.writeSynchronously { session in
            let channelDTO = try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(payload: payload1, cache: nil)
            try session.saveThread(payload: payload2, cache: nil)
            try session.saveThread(payload: payload3, cache: nil)
            try session.saveThread(payload: payload4, cache: nil)
        }

        // A fetch request with a default sorting (unread, lastMessageAt, parentMessageId).
        let fetchRequestWithDefaultSorting = ThreadDTO.threadListFetchRequest(query: queryWithDefaultSorting)
        // A fetch request with a sorting by `updatedAt`.
        let fetchRequestWithUpdatedAtSorting = ThreadDTO.threadListFetchRequest(query: queryWithUpdatedAtSorting)

        var threadsWithDefaultSorting: [ThreadDTO] { 
            try! database.viewContext.fetch(fetchRequestWithDefaultSorting) 
        }
        var threadsWithUpdatedAtSorting: [ThreadDTO] { 
            try! database.viewContext.fetch(fetchRequestWithUpdatedAtSorting) 
        }

        // Check the default sorting (by lastMessageAt in this case since no unread).
        XCTAssertEqual(threadsWithDefaultSorting.count, 4)
        let sortedByLastMessage = threadsWithDefaultSorting.map { $0.parentMessageId }
        let expectedLastMessageOrder = [
            payload4.parentMessageId, // most recent
            payload3.parentMessageId,
            payload2.parentMessageId,
            payload1.parentMessageId  // oldest
        ]
        XCTAssertEqual(sortedByLastMessage, expectedLastMessageOrder)

        // Check the sorting by `updatedAt`.
        XCTAssertEqual(threadsWithUpdatedAtSorting.count, 4)

        let sortedByUpdatedAt = threadsWithUpdatedAtSorting.map { $0.parentMessageId }
        let expectedUpdatedAtOrder = [
            payload2.parentMessageId, // most recent
            payload1.parentMessageId,
            payload3.parentMessageId,
            payload4.parentMessageId  // oldest
        ]
        XCTAssertEqual(sortedByUpdatedAt, expectedUpdatedAtOrder)
    }

    func test_threadListFetchRequest_appliesCorrectSortDescriptors() {
        let query = ThreadListQuery(
            watch: true,
            sort: [
                .init(key: .replyCount, isAscending: true),
                .init(key: .participantCount, isAscending: false)
            ]
        )

        let fetchRequest = ThreadDTO.threadListFetchRequest(query: query)
        let sortDescriptors = fetchRequest.sortDescriptors

        XCTAssertEqual(sortDescriptors?.count, 2)
        XCTAssertEqual(sortDescriptors?[0].key, "replyCount")
        XCTAssertTrue(sortDescriptors?[0].ascending == true)
        XCTAssertEqual(sortDescriptors?[1].key, "participantCount")
        XCTAssertTrue(sortDescriptors?[1].ascending == false)
    }

    func test_threadListFetchRequest_usesDefaultSorting_whenNoSortProvided() {
        let query = ThreadListQuery(watch: true, sort: [])

        let fetchRequest = ThreadDTO.threadListFetchRequest(query: query)
        let sortDescriptors = fetchRequest.sortDescriptors

        XCTAssertEqual(sortDescriptors?.count, 3)
        XCTAssertEqual(sortDescriptors?[0].key, "currentUserUnreadCount")
        XCTAssertTrue(sortDescriptors?[0].ascending == false)
        XCTAssertEqual(sortDescriptors?[1].key, "lastMessageAt")
        XCTAssertTrue(sortDescriptors?[1].ascending == false)
        XCTAssertEqual(sortDescriptors?[2].key, "parentMessageId")
        XCTAssertTrue(sortDescriptors?[2].ascending == false)
    }
}
