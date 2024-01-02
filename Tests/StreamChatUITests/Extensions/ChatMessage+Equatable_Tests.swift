//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

#if swift(>=5.7)
@available(iOS 16.0, *)
final class ChatMessage_Equatable_Tests: XCTestCase {
    var database: DatabaseContainer!
    let numberOfMessages = 100

    func test_allTests() throws {
        try XCTSkipIf(true, "Meant to be used locally")

        let base: ContinuousClock.Instant.Duration = try test_isContentEqual_sameArray()

        print("📊 Results -------------")
        try [
            ("Same array (1)", base),
            ("Same array (2)", try test_isContentEqual_sameArray()),
            ("Same array (3)", try test_isContentEqual_sameArray()),
            ("Reversed array", test_isContentEqual_reversedArray()),
            ("Changing text", test_isContentEqual_changingText())
        ].forEach {
            print("\($0), \($1), \(base - $1)")
        }
        print("📊 ---------------------")
    }

    func test_isContentEqual_sameArray() throws -> ContinuousClock.Instant.Duration {
        database = DatabaseContainer_Spy()

        let clock = ContinuousClock()

        let lhs = try createMessages(numberOfMessages: numberOfMessages)
        let rhs = try createMessages(numberOfMessages: numberOfMessages)

        var results: [Bool] = []

        let duration = clock.measure {
            results.append(lhs.isContentEqual(to: rhs))
        }

        XCTAssertTrue(results.reduce(true) { $0 && $1 })
        return duration
    }

    func test_isContentEqual_reversedArray() throws -> ContinuousClock.Instant.Duration {
        database = DatabaseContainer_Spy()

        let clock = ContinuousClock()

        let lhs = try createMessages(numberOfMessages: numberOfMessages)
        let rhs = try Array(createMessages(numberOfMessages: numberOfMessages).reversed())

        var results: [Bool] = []

        let duration = clock.measure {
            results.append(lhs.isContentEqual(to: rhs))
        }

        XCTAssertFalse(results.reduce(true) { $0 && $1 })
        return duration
    }

    func test_isContentEqual_changingText() throws -> ContinuousClock.Instant.Duration {
        database = DatabaseContainer_Spy()

        let clock = ContinuousClock()
        let lhs = try createMessages(numberOfMessages: numberOfMessages, changingText: false)
        let rhs = try createMessages(numberOfMessages: numberOfMessages, changingText: true)

        var results: [Bool] = []
        let duration = clock.measure {
            results.append(lhs.isContentEqual(to: rhs))
        }
        XCTAssertFalse(results.reduce(true) { $0 && $1 })

        return duration
    }

    private func createMessages(
        numberOfMessages: Int,
        changingText: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [ChatMessage] {
        let channelId = ChannelId.unique

        let numberOfUsers = numberOfMessages
        let numberOfReactions = 2
        let numberOfReads = 10
        let numberOfAttachments = 2
        let numberOfThreadParticipants = 4
        let numberOfMentionedUsers = 2

        var messages: [ChatMessage] = []

        try database.writeSynchronously { session in
            var previousMessages: [MessageDTO] = []
            var previousMessage: MessageDTO? {
                previousMessages.last
            }
            let createdUsers: [UserDTO] = try (0...numberOfUsers).map { index in
                try session.saveUser(payload: self.userPayload(id: index))
            }

            let extraData: Data = try {
                let extraData: [String: RawJSON] = [
                    "1": .array([
                        .bool(true), .bool(false)
                    ]),
                    "2": .dictionary([
                        "another": .string("hello")
                    ])
                ]

                return try JSONEncoder.default.encode(extraData)
            }()

            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .admin))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))

            try (1...numberOfMessages).forEach { index in
                let message = try session.createNewMessage(
                    in: channelId,
                    messageId: "message-id-\(index)",
                    text: changingText ? "edited-message-\(index)" : "message\(index)",
                    pinning: nil,
                    quotedMessageId: nil,
                    skipPush: true,
                    skipEnrichUrl: true
                )

                let reactions = try (1...numberOfReactions).map { index in
                    try session.saveReaction(
                        payload: .dummy(type: .init(rawValue: "reaction-\(index)"), messageId: message.id, user: self.userPayload(id: index)),
                        cache: nil
                    )
                }

                let reads = try (1...numberOfReads).map { index in
                    try session.saveChannelRead(
                        payload: .init(
                            user: self.userPayload(id: index),
                            lastReadAt: previousMessage?.createdAt.bridgeDate ?? Date(),
                            lastReadMessageId: previousMessage?.id,
                            unreadMessagesCount: index
                        ),
                        for: channelId,
                        cache: nil
                    )
                }

                let attachments = try (1...numberOfAttachments).map { index in
                    let payload = AnyAttachmentPayload(payload: TestAttachmentPayload(name: "name-\(index)", number: index))
                    let attachmentId = AttachmentId(cid: channelId, messageId: message.id, index: index)
                    return try session.createNewAttachment(attachment: payload, id: attachmentId)
                }

                // THEORY:

                // Cheap
                message.type = "type-\(index)"
                message.command = "command-\(index)"
                message.args = "args-\(index)"
                message.parentMessageId = previousMessage?.id
                message.showReplyInChannel = index % 2 == 0
                message.isShadowed = index % 2 == 0
                message.localMessageState = nil

                // Medium
                message.reactionCounts = [
                    "first-\(index)": index,
                    "second-\(index)": index
                ]
                message.reactionScores = [
                    "first-\(index)": index,
                    "second-\(index)": index
                ]

                message.user = createdUsers[index]

                // Expensive
                message.extraData = extraData
                message.quotedMessage = index % 2 == 0 ? previousMessage : nil
                message.ownReactions = reactions.map(\.id)
                message.threadParticipants = NSOrderedSet(array: createdUsers.getRandom(amount: numberOfThreadParticipants))
                message.reads = Set(reads)
                message.attachments = Set(attachments)

                // Currently unused
                message.replyCount = 3
                message.latestReactions = reactions.map(\.id)
                message.replies = []
                message.mentionedUsers = Set(createdUsers.getRandom(amount: numberOfMentionedUsers))

                previousMessages.append(message)
            }

            messages = try previousMessages.map { try $0.asModel() }
        }

        XCTAssertEqual(messages.count, numberOfMessages)
        return messages
    }

    private func userPayload(id: Int) -> UserPayload {
        let userId = "user-\(id)"
        return UserPayload(
            id: userId,
            name: userId,
            imageURL: nil,
            role: .user,
            createdAt: Date(timeIntervalSince1970: 3),
            updatedAt: Date(timeIntervalSince1970: 3),
            deactivatedAt: Date(timeIntervalSince1970: 3),
            lastActiveAt: Date(timeIntervalSince1970: 3),
            isOnline: true,
            isInvisible: true,
            isBanned: false,
            teams: [],
            language: nil,
            extraData: [:]
        )
    }
}

extension Collection {
    func getRandom() -> Element {
        guard count > 0 else {
            fatalError()
        }
        return randomElement()!
    }

    func getRandom(amount: Int) -> [Element] {
        (0...amount).map { _ in
            self.getRandom()
        }
    }
}
#endif
