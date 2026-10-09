//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ScheduledMessagesRepository_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var repository: ScheduledMessagesRepository!
    var cid: ChannelId!
    var userIds: [UserId] = []

    override func setUp() {
        super.setUp()

        client = ChatClient.mock
        cid = .unique
        switchUser()
        let simulator = ScheduledMessagesSimulator(client: client, responseDelay: 0, deliveryInterval: 3600)
        repository = ScheduledMessagesRepository(client: client, simulator: simulator)
    }

    override func tearDown() {
        userIds.forEach {
            UserDefaults.standard.removeObject(forKey: "io.getstream.chat.simulated-scheduled-messages.\($0)")
        }
        userIds = []
        repository = nil
        client = nil
        cid = nil

        super.tearDown()
    }

    // MARK: - Schedule

    func test_schedule_returnsTheScheduledMessage_andAddsItToTheList() throws {
        let scheduledAt = Date().addingTimeInterval(3600)

        let message = try schedule(text: "Hello", scheduledAt: scheduledAt).get()

        XCTAssertEqual(message.text, "Hello")
        XCTAssertEqual(message.cid, cid)
        XCTAssertEqual(message.scheduledAt, scheduledAt)
        XCTAssertEqual(message.status, .scheduled)
        XCTAssertEqual(repository.scheduledMessages, [message])
    }

    func test_schedule_withTheSameId_returnsTheExistingMessage() throws {
        let first = try schedule(id: "scheduled-id", text: "First").get()
        let second = try schedule(id: "scheduled-id", text: "Second").get()

        XCTAssertEqual(second, first)
        XCTAssertEqual(repository.scheduledMessages.count, 1)
    }

    func test_schedule_lessThanAMinuteAhead_fails() {
        let result = schedule(scheduledAt: Date().addingTimeInterval(30))

        XCTAssertEqual(errorMessage(result), "Pick a time at least 1 minute from now")
    }

    func test_schedule_moreThan120DaysAhead_fails() {
        let result = schedule(scheduledAt: Date().addingTimeInterval(121 * 24 * 60 * 60))

        XCTAssertEqual(errorMessage(result), "Pick a time within 120 days")
    }

    func test_schedule_aboveTheChannelLimit_fails() throws {
        for _ in 0..<ScheduledMessagesSimulator.channelLimit {
            _ = try schedule().get()
        }

        let result = schedule()

        XCTAssertEqual(errorMessage(result), "You can schedule up to 10 messages in this channel")
    }

    // MARK: - Update

    func test_reschedule_changesTheDate_andKeepsTheContent() throws {
        let message = try schedule(text: "Hello").get()
        let newDate = Date().addingTimeInterval(7200)

        let rescheduled = try waitFor { repository.reschedule(id: message.id, scheduledAt: newDate, completion: $0) }.get()

        XCTAssertEqual(rescheduled.scheduledAt, newDate)
        XCTAssertEqual(rescheduled.text, "Hello")
        XCTAssertEqual(repository.scheduledMessages, [rescheduled])
    }

    func test_update_changesTheContent() throws {
        let message = try schedule(text: "Hello").get()

        let updated = try waitFor {
            repository.update(id: message.id, content: content(text: "Updated"), scheduledAt: nil, completion: $0)
        }.get()

        XCTAssertEqual(updated.text, "Updated")
        XCTAssertEqual(updated.scheduledAt, message.scheduledAt)
        XCTAssertEqual(repository.scheduledMessage(id: message.id)?.text, "Updated")
    }

    // MARK: - Delete

    func test_delete_removesTheMessage() throws {
        let message = try schedule().get()

        let error = try waitFor { repository.delete(id: message.id, completion: $0) }

        XCTAssertNil(error)
        XCTAssertEqual(repository.scheduledMessages, [])
    }

    func test_delete_unknownMessage_fails() throws {
        let error = try waitFor { repository.delete(id: "unknown", completion: $0) }

        XCTAssertEqual(errorMessage(.failure(error ?? ClientError())), "This scheduled message no longer exists")
    }

    // MARK: - Load

    func test_load_returnsTheMessagesOfTheCurrentUserOnly() throws {
        let message = try schedule().get()

        let page = try waitFor { repository.load(query: .init(), completion: $0) }.get()
        XCTAssertEqual(page.messages, [message])
        XCTAssertNil(page.next)

        switchUser()
        let otherUserPage = try waitFor { repository.load(query: .init(), completion: $0) }.get()
        XCTAssertEqual(otherUserPage.messages, [])
        XCTAssertEqual(repository.scheduledMessages, [])
    }

    func test_load_paginates() throws {
        for _ in 0..<3 {
            _ = try schedule().get()
        }

        let firstPage = try waitFor { repository.load(query: .init(pageSize: 2), completion: $0) }.get()
        let secondPage = try waitFor {
            repository.load(query: .init(pageSize: 2, next: firstPage.next), completion: $0)
        }.get()

        XCTAssertEqual(firstPage.messages.count, 2)
        XCTAssertNotNil(firstPage.next)
        XCTAssertEqual(secondPage.messages.count, 1)
        XCTAssertNil(secondPage.next)
    }

    // MARK: - Local queries

    func test_query_sortsPendingMessagesFirst_thenByScheduledAt() {
        let later = makeMessage(scheduledAt: Date().addingTimeInterval(200))
        let failed = makeMessage(scheduledAt: Date().addingTimeInterval(50), status: .failed)
        let sooner = makeMessage(scheduledAt: Date().addingTimeInterval(100))

        let sorted = ScheduledMessageListQuery().sorted([later, failed, sooner])

        XCTAssertEqual(sorted.map(\.id), [sooner.id, later.id, failed.id])
    }

    func test_query_sortsBySortingKeys() {
        let first = makeMessage(scheduledAt: Date().addingTimeInterval(100))
        let second = makeMessage(scheduledAt: Date().addingTimeInterval(200))

        let sorted = ScheduledMessageListQuery(sort: [.init(key: .scheduledAt, isAscending: false)]).sorted([first, second])

        XCTAssertEqual(sorted.map(\.id), [second.id, first.id])
    }

    func test_query_filtersByStatusAndChannel() {
        let otherCid = ChannelId.unique
        let pending = makeMessage()
        let failed = makeMessage(status: .failed)
        let sending = makeMessage(status: .sending)
        let otherChannel = makeMessage(cid: otherCid)
        let messages = [pending, failed, sending, otherChannel]

        let pendingQuery = ScheduledMessageListQuery(filter: .and([.pending, .equal(.cid, to: cid)]))
        let failedQuery = ScheduledMessageListQuery(filter: .failed)
        let channelsQuery = ScheduledMessageListQuery(filter: .in(.cid, values: [otherCid]))

        XCTAssertEqual(messages.filter(pendingQuery.matches).map(\.id), [pending.id, sending.id])
        XCTAssertEqual(messages.filter(failedQuery.matches).map(\.id), [failed.id])
        XCTAssertEqual(messages.filter(channelsQuery.matches).map(\.id), [otherChannel.id])
    }

    // MARK: - Helpers

    private func switchUser() {
        let userId = UserId.unique
        userIds.append(userId)
        client.currentUserId_mock = userId
    }

    private func content(text: String = "Hello") -> ScheduledMessageContent {
        ScheduledMessageContent(
            text: text,
            attachments: [],
            mentionedUserIds: [],
            quotedMessageId: nil,
            parentId: nil,
            showReplyInChannel: false,
            extraData: [:]
        )
    }

    private func schedule(
        id: String = .unique,
        text: String = "Hello",
        scheduledAt: Date = Date().addingTimeInterval(3600)
    ) -> Result<ScheduledMessage, Error> {
        do {
            return try waitFor {
                repository.schedule(id: id, cid: cid, content: content(text: text), scheduledAt: scheduledAt, completion: $0)
            }
        } catch {
            return .failure(error)
        }
    }

    private func errorMessage(_ result: Result<ScheduledMessage, Error>) -> String? {
        guard case let .failure(error) = result else { return nil }
        return ((error as? ClientError)?.underlyingError as? APIError)?.message
    }

    private func makeMessage(
        cid: ChannelId? = nil,
        scheduledAt: Date = Date().addingTimeInterval(3600),
        status: ScheduledMessageStatus = .scheduled
    ) -> ScheduledMessage {
        ScheduledMessage(
            id: .unique,
            cid: cid ?? self.cid,
            channel: nil,
            text: "Hello",
            attachments: [],
            mentionedUserIds: [],
            quotedMessageId: nil,
            parentMessageId: nil,
            showReplyInChannel: false,
            extraData: [:],
            scheduledAt: scheduledAt,
            status: status,
            failureReason: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
