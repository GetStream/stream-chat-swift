//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageLayoutOptionsResolver_Tests: XCTestCase {
    private var optionsResolver: ChatMessageLayoutOptionsResolver!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        optionsResolver = .init()
    }

    override func tearDown() {
        super.tearDown()

        optionsResolver = nil
    }

    // MARK: - Flipped

    func test_optionsForMessage_whenMessageIsSentByCurrentUser_includesFlipped() {
        // Create a message sent NOT by the current user
        let messageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByCurrentUser])
        )

        // Assert `.flipped` is included
        XCTAssertTrue(layoutOptions.contains(.flipped))
    }

    func test_optionsForMessage_whenMessageIsSentNotByCurrentUser_doesNotIncludeFlipped() {
        // Create a message sent by another current user
        let messageSentNotByCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentNotByCurrentUser])
        )

        // Assert `.flipped` is not included
        XCTAssertFalse(layoutOptions.contains(.flipped))
    }

    // MARK: - Bubble

    func test_optionsForMessage_includesBubbleByDefault() {
        let channelHistory: [(ChatMessage, Bool)] = .directMessagesHistory(
            minTimeIntervalBetweenMessagesInGroup: optionsResolver.minTimeIntervalBetweenMessagesInGroup
        )

        for message in channelHistory.map(\.0) {
            // Calculate layout options for the current message
            let layoutOptions = optionsResolver.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([message])
            )

            // Assert `.bubble` is included
            XCTAssertTrue(layoutOptions.contains(.bubble))
        }
    }

    // MARK: - Continuous bubble

    func test_optionsForMessage_whenMessageIsLastInSequence_doesNotIncludeContinuousBubble() {
        for isSentByCurrentUser in [true, false] {
            // Create message
            let message: ChatMessage = .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Calculate layout options for the message
            let layoutOptions = optionsResolver.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([message])
            )

            // Assert `.continuousBubble` is not included
            XCTAssertFalse(layoutOptions.contains(.continuousBubble))
        }
    }

    func test_optionsForMessage_whenMessageIsNotLastInSequence_includesContinuousBubble() {
        // Create a user
        let user: ChatUser = .mock(id: .unique)

        for isSentByCurrentUser in [true, false] {
            // Create a message
            let message1: ChatMessage = .mock(
                id: .unique,
                text: .unique,
                author: user,
                createdAt: Date(),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Create a previous message sent by the same user within `minTimeIntervalBetweenMessagesInGroup` timeframe
            let message2: ChatMessage = .mock(
                id: .unique,
                text: .unique,
                author: user,
                createdAt: message1.createdAt.addingTimeInterval(
                    -(optionsResolver.minTimeIntervalBetweenMessagesInGroup - 1)
                ),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Calculate layout options for the second message
            let layoutOptions = optionsResolver.optionsForMessage(
                at: .init(item: 1, section: 0),
                in: .mock(cid: .unique),
                with: .init([message1, message2])
            )

            // Assert `.continuousBubble` is included
            XCTAssertTrue(layoutOptions.contains(.continuousBubble))
        }
    }

    func test_optionsForMessage_whenMessageBelongsToThread_includesContinuousBubble() {
        // Create non-deleted thread root message
        let messageThreadRoot: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, text: .unique, author: .mock(id: .unique))
            ]
        )

        // Create non-deleted thread part message
        let messageThreadPart: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: messageThreadRoot.id
        )

        for threadMessage in [messageThreadRoot, messageThreadPart] {
            // Calculate layout options for the message
            let layoutOptions = optionsResolver.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([threadMessage])
            )

            // Assert `.continuousBubble` is included
            XCTAssertTrue(layoutOptions.contains(.continuousBubble))
        }
    }

    // MARK: - Avatar size padding

    func test_optionsForMessage_whenMessageIsSentByCurrentUser_doesNotIncludeAvatarSizePadding() {
        // Create non-deleted message sent by current user
        let messageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByCurrentUser])
        )

        // Assert `.avatarSizePadding` is not included since the message is sent by current user
        XCTAssertFalse(layoutOptions.contains(.avatarSizePadding))
    }

    func test_optionsForMessage_whenMessageSentByAnotherUserIsNotLastInSequence_includesAvatarSizePadding() {
        // Create a user
        let anotherUser: ChatUser = .mock(id: .unique)

        // Create last message from another user
        let messageFromAnotherUser1: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: Date(),
            isSentByCurrentUser: false
        )

        // Create message from another user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let messageFromAnotherUser2: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: messageFromAnotherUser1.createdAt.addingTimeInterval(
                -(optionsResolver.minTimeIntervalBetweenMessagesInGroup - 1)
            ),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the second message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 1, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageFromAnotherUser1, messageFromAnotherUser2])
        )

        // Assert `.avatarSizePadding` is included
        XCTAssertTrue(layoutOptions.contains(.avatarSizePadding))
    }

    func test_optionsForMessage_whenMessageSentByAnotherUserIsLastInSequence_includesAvatarSizePadding() {
        // Create ephemeral message sent by another user
        let messageSentByAnotherUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByAnotherUser])
        )

        // Assert `.avatarSizePadding` is not included since for the last message the avatar is shown
        XCTAssertFalse(layoutOptions.contains(.avatarSizePadding))
    }

    // MARK: - Timestamp

    func test_optionsForMessage_whenMessageIsLastInSequence_includesTimestamp() {
        for isSentByCurrentUser in [true, false] {
            // Create message
            let message: ChatMessage = .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Calculate layout options for the message
            let layoutOptions = optionsResolver.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([message])
            )

            // Assert `.timestamp` is included
            XCTAssertTrue(layoutOptions.contains(.timestamp))
        }
    }

    func test_optionsForMessage_whenMessageIsNotLastInSequence_doesNotIncludeTimestamp() {
        // Create a user
        let user: ChatUser = .mock(id: .unique)

        for isSentByCurrentUser in [true, false] {
            // Create a message
            let message1: ChatMessage = .mock(
                id: .unique,
                text: .unique,
                author: user,
                createdAt: Date(),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Create a previous message sent by the same user within `minTimeIntervalBetweenMessagesInGroup` timeframe
            let message2: ChatMessage = .mock(
                id: .unique,
                text: .unique,
                author: user,
                createdAt: message1.createdAt.addingTimeInterval(
                    -(optionsResolver.minTimeIntervalBetweenMessagesInGroup - 1)
                ),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Calculate layout options for the second message
            let layoutOptions = optionsResolver.optionsForMessage(
                at: .init(item: 1, section: 0),
                in: .mock(cid: .unique),
                with: .init([message1, message2])
            )

            // Assert `.timestamp` is not included since the message is not the last in sequence
            XCTAssertFalse(layoutOptions.contains(.timestamp))
        }
    }

    // MARK: - Only visible for current user

    func test_optionsForMessage_whenMessageIsNotSentByCurrentUser_doesNotIncludeOnlyVisibleForYouIndicator() {
        // Create ephemeral message sent by another user
        let messageSentByAnotherUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByAnotherUser])
        )

        // Assert `.onlyVisibleForYouIndicator` is included
        XCTAssertFalse(layoutOptions.contains(.onlyVisibleForYouIndicator))
    }

    func test_optionsForMessage_whenMessageSentByCurrentUserIsEphemeral_includesOnlyVisibleForYouIndicator() {
        // Create ephemeral message sent by current user
        let ephemeralMessageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([ephemeralMessageSentByCurrentUser])
        )

        // Assert `.onlyVisibleForYouIndicator` is included
        XCTAssertTrue(layoutOptions.contains(.onlyVisibleForYouIndicator))
    }

    func test_optionsForMessage_whenMessageSentByCurrentUserIsDeleted_includesOnlyVisibleForYouIndicator() {
        // Create ephemeral message sent by current user
        let deletedMessageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessageSentByCurrentUser])
        )

        // Assert `.onlyVisibleForYouIndicator` is included
        XCTAssertTrue(layoutOptions.contains(.onlyVisibleForYouIndicator))
    }

    // MARK: - Text

    func test_optionsForMessage_whenMessageIsEphemeral_doesNotIncludeText() {
        // Create ephemeral message
        let ephemeralMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique)
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([ephemeralMessage])
        )

        // Assert `.text` is not included
        XCTAssertFalse(layoutOptions.contains(.text))
    }

    func test_optionsForMessage_whenMessageIsDeleted_includesText() {
        // Create deleted message
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessage])
        )

        // Assert `.text` is included
        XCTAssertTrue(layoutOptions.contains(.text))
    }

    func test_optionsForMessage_whenMessageHasText_includesText() {
        // Create non-ephemeral non-deleted message with text
        let message: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique)
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([message])
        )

        // Assert `.text` is included
        XCTAssertTrue(layoutOptions.contains(.text))
    }

    // MARK: - Avatar

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeAvatar() {
        // Create deleted message last in sequence by another user
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: false
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessage])
        )

        // Assert `.avatar` is not included since the message is deleted
        XCTAssertFalse(layoutOptions.contains(.avatar))
    }

    func test_optionsForMessage_whenMessageIsSentByCurrentUser_doesNotIncludeAvatar() {
        // Create non-deleted message sent by current user that ends the sequence
        let messageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByCurrentUser])
        )

        // Assert `.avatar` is not included since the message is sent by current user
        XCTAssertFalse(layoutOptions.contains(.avatar))
    }

    func test_optionsForMessage_whenMessageSentByAnotherUserIsNotLastInSequence_doesNotIncludeAvatar() {
        // Create a user
        let anotherUser: ChatUser = .mock(id: .unique)

        // Create last message from current user
        let messageFromAnotherUser1: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: Date(),
            isSentByCurrentUser: false
        )

        // Create message from current user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let messageFromAnotherUser2: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: messageFromAnotherUser1.createdAt.addingTimeInterval(
                -(optionsResolver.minTimeIntervalBetweenMessagesInGroup - 1)
            ),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the second message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 1, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageFromAnotherUser1, messageFromAnotherUser2])
        )

        // Assert `.avatar` is not included since the message is not the sequence end
        XCTAssertFalse(layoutOptions.contains(.avatar))
    }

    func test_optionsForMessage_whenMessageSentByAnotherUserIsLastInSequence_includesAvatar() {
        // Create a user
        let anotherUser: ChatUser = .mock(id: .unique)

        // Create last message from current user
        let messageFromAnotherUser1: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: Date(),
            isSentByCurrentUser: false
        )

        // Create message from current user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let messageFromAnotherUser2: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: messageFromAnotherUser1.createdAt.addingTimeInterval(
                -(optionsResolver.minTimeIntervalBetweenMessagesInGroup - 1)
            ),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the last message in sequence
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageFromAnotherUser1, messageFromAnotherUser2])
        )

        // Assert `.avatar` is included
        XCTAssertTrue(layoutOptions.contains(.avatar))
    }
    
    // MARK: - Author name

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeAuthorName() {
        // Create deleted message
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        // Create a channel where > 2 members can be
        let notDMChannel: ChatChannel = .mock(
            cid: .init(type: .livestream, id: .unique)
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: notDMChannel,
            with: .init([deletedMessage])
        )

        // Assert `.authorName` is not included since the message is deleted
        XCTAssertFalse(layoutOptions.contains(.authorName))
    }

    func test_optionsForMessage_whenMessageIsSentByCurrentUser_doesNotIncludeAuthorName() {
        // Create non-deleted message sent by current user
        let messageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Create a channel where > 2 members can be
        let notDMChannel: ChatChannel = .mock(
            cid: .init(type: .livestream, id: .unique)
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: notDMChannel,
            with: .init([messageSentByCurrentUser])
        )

        // Assert `.authorName` is not included since the message is sent by current user
        XCTAssertFalse(layoutOptions.contains(.authorName))
    }

    func test_optionsForMessage_whenMessageIsNotLastInSequence_doesNotIncludeAuthorName() {
        // Create a user
        let anotherUser: ChatUser = .mock(id: .unique)

        // Create last message from current user
        let messageFromAnotherUser1: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: Date(),
            isSentByCurrentUser: false
        )

        // Create message from current user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let messageFromAnotherUser2: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: messageFromAnotherUser1.createdAt.addingTimeInterval(
                -(optionsResolver.minTimeIntervalBetweenMessagesInGroup - 1)
            ),
            isSentByCurrentUser: false
        )

        // Create a channel where > 2 members can be
        let notDMChannel: ChatChannel = .mock(
            cid: .init(type: .livestream, id: .unique)
        )

        // Calculate layout options for the second message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 1, section: 0),
            in: notDMChannel,
            with: .init([messageFromAnotherUser1, messageFromAnotherUser2])
        )

        // Assert `.authorName` is not included since the message is not the sequence end
        XCTAssertFalse(layoutOptions.contains(.authorName))
    }

    func test_optionsForMessage_whenChannelIsDirectMessaging_doesNotIncludeAuthorName() {
        // Create last message from current user
        let messageFromAnotherUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Create a DM channel
        let directMessagesChannel: ChatChannel = .mockDMChannel()

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: directMessagesChannel,
            with: .init([messageFromAnotherUser])
        )

        // Assert `.authorName` is not included since the channel is DM
        XCTAssertFalse(layoutOptions.contains(.authorName))
    }

    func test_optionsForMessage_whenMessageEndsTheSequenceSentByAnotherUserAndChannelIsNotDM_includesAuthorName() {
        // Create last message from current user
        let messageFromAnotherUser: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Create a channel where > 2 members can be
        let notDMChannel: ChatChannel = .mock(
            cid: .init(type: .livestream, id: .unique)
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: notDMChannel,
            with: .init([messageFromAnotherUser])
        )

        // Assert `.authorName` is included
        XCTAssertTrue(layoutOptions.contains(.authorName))
    }

    // MARK: - Quoted message

    func test_optionsForMessage_whenMessageHasQuotedMessage_includesQuotedMessage() {
        // Create non-deleted message with quoted message
        let messageWithQuotedMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            quotedMessage: .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique)
            )
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageWithQuotedMessage])
        )

        // Assert `.quotedMessage` is included
        XCTAssertTrue(layoutOptions.contains(.quotedMessage))
    }

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeQuotedMessage() {
        // Create deleted message with quoted message
        let deletedMessageWithQuotedMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            quotedMessage: .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique)
            )
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessageWithQuotedMessage])
        )

        // Assert `.quotedMessage` is not included because message is deleted
        XCTAssertFalse(layoutOptions.contains(.quotedMessage))
    }

    // MARK: - Thread info

    func test_optionsForMessage_whenMessageBelongsToThread_includesThreadInfo() {
        // Create non-deleted thread root message
        let messageThreadRoot: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, text: .unique, author: .mock(id: .unique))
            ]
        )

        // Create non-deleted thread part message
        let messageThreadPart: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: messageThreadRoot.id
        )

        for threadMessage in [messageThreadRoot, messageThreadPart] {
            // Calculate layout options for the message
            let layoutOptions = optionsResolver.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([threadMessage])
            )

            // Assert `.threadInfo` is included
            XCTAssertTrue(layoutOptions.contains(.threadInfo))
        }
    }

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeThreadInfo() {
        // Create deleted thread root message
        let messageThreadRoot: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, text: .unique, author: .mock(id: .unique))
            ]
        )

        // Create deleted thread part message
        let messageThreadPart: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            parentMessageId: messageThreadRoot.id
        )

        for threadMessage in [messageThreadRoot, messageThreadPart] {
            // Calculate layout options for the message
            let layoutOptions = optionsResolver.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([threadMessage])
            )

            // Assert `.threadInfo` is not included since message is deleted
            XCTAssertFalse(layoutOptions.contains(.threadInfo))
        }
    }

    // MARK: - Reactions

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeReactions() {
        // Create deleted message with reactions
        let deletedMessageWithReactions: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            reactionScores: ["like": 1],
            latestReactions: [
                .init(
                    type: "like",
                    score: 1,
                    createdAt: .unique,
                    updatedAt: .unique,
                    extraData: .defaultValue,
                    author: .mock(id: .unique)
                )
            ]
        )

        // Create channel with enabled reactions
        let channelWithReactionsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(reactionsEnabled: true)
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channelWithReactionsEnabled,
            with: .init([deletedMessageWithReactions])
        )

        // Assert `.reactions` is not included since message is deleted
        XCTAssertFalse(layoutOptions.contains(.reactions))
    }

    func test_optionsForMessage_whenMessageHasReactionsAndChannelEnablesReactions_includesReactions() {
        // Create non-deleted message with reactions
        let messageWithReactions: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            reactionScores: ["like": 1],
            latestReactions: [
                .init(
                    type: "like",
                    score: 1,
                    createdAt: .unique,
                    updatedAt: .unique,
                    extraData: .defaultValue,
                    author: .mock(id: .unique)
                )
            ]
        )

        // Create channel with enabled reactions
        let channelWithReactionsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(reactionsEnabled: true)
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channelWithReactionsEnabled,
            with: .init([messageWithReactions])
        )

        // Assert `.reactions` is included
        XCTAssertTrue(layoutOptions.contains(.reactions))
    }

    func test_optionsForMessage_whenMessageHasReactionsButChannelDisablesReactions_doesNotIncludesReactions() {
        // Create non-deleted message with reactions
        let messageWithReactions: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            reactionScores: ["like": 1],
            latestReactions: [
                .init(
                    type: "like",
                    score: 1,
                    createdAt: .unique,
                    updatedAt: .unique,
                    extraData: .defaultValue,
                    author: .mock(id: .unique)
                )
            ]
        )

        // Create channel with disabled reactions
        let channelWithReactionsDisabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(reactionsEnabled: false)
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channelWithReactionsDisabled,
            with: .init([messageWithReactions])
        )

        // Assert `.reactions` is not included
        XCTAssertFalse(layoutOptions.contains(.reactions))
    }

    func test_optionsForMessage_whenMessageHasNoReactions_doesNotIncludeReactions() {
        // Create non-deleted message without reactions
        let messageWithoutReactions: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            reactionScores: [:],
            latestReactions: []
        )

        // Create channel with enabled reactions
        let channelWithReactionsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(reactionsEnabled: true)
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channelWithReactionsEnabled,
            with: .init([messageWithoutReactions])
        )

        // Assert `.reactions` is not included
        XCTAssertFalse(layoutOptions.contains(.reactions))
    }

    // MARK: - Error indicator

    func test_optionsForMessage_whenMessageHasFailedState_includesErrorIndicator() {
        for failedState: LocalMessageState in [.sendingFailed, .syncingFailed, .deletingFailed] {
            // Create non-deleted message with failed local state
            let messageWithFailedState: ChatMessage = .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                deletedAt: nil,
                localState: failedState,
                isSentByCurrentUser: true
            )

            // Calculate layout options for the message
            let layoutOptions = optionsResolver.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([messageWithFailedState])
            )

            // Assert `.errorIndicator` is included
            XCTAssertTrue(layoutOptions.contains(.errorIndicator))
        }
    }

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeErrorIndicator() {
        // Create deleted message
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        // Calculate layout options for the message
        let layoutOptions = optionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessage])
        )

        // Assert `.errorIndicator` is not included
        XCTAssertFalse(layoutOptions.contains(.errorIndicator))
    }

    // MARK: - Is message

    func test_isMessageLastInSequence() {
        // Get mock channel history
        let testCases: [(ChatMessage, Bool)] = .directMessagesHistory(
            minTimeIntervalBetweenMessagesInGroup: optionsResolver.minTimeIntervalBetweenMessagesInGroup
        )

        // Iterate test cases
        for (index, testCase) in testCases.enumerated() {
            // Get the expected value
            let isStandaloneOrLastInSequence = testCase.1

            // Assert the actual value matches the expected one.
            XCTAssertEqual(
                optionsResolver.isMessageLastInSequence(
                    messageIndexPath: .init(item: index, section: 0),
                    messages: .init(testCases.map(\.0))
                ),
                isStandaloneOrLastInSequence
            )
        }
    }
}

private extension Array where Element == (ChatMessage, Bool) {
    static func directMessagesHistory(
        currentUser: ChatUser = .mock(id: .unique),
        anotherUser: ChatUser = .mock(id: .unique),
        minTimeIntervalBetweenMessagesInGroup: TimeInterval = 10
    ) -> [Element] {
        // Create last message from current user with last action failed
        let message0WithLastActionFailed: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: currentUser,
            createdAt: Date(),
            localState: .syncingFailed,
            isSentByCurrentUser: true
        )

        // Create previous message from current user within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message1: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: currentUser,
            createdAt: message0WithLastActionFailed.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup - 1)),
            isSentByCurrentUser: true
        )

        // Create previous message from current user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message2WithoutText: ChatMessage = .mock(
            id: .unique,
            text: "",
            author: currentUser,
            createdAt: message1.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup - 1)),
            isSentByCurrentUser: true
        )

        // Create previous message from current user sent outside `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message3: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: currentUser,
            createdAt: message2WithoutText.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup + 1)),
            isSentByCurrentUser: true
        )

        // Create previous message from another user within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message4: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: message3.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup - 1))
        )

        // Create previous message from another user with reactions within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message5WithReactions: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: message4.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup - 1)),
            reactionScores: ["like": 1],
            latestReactions: [
                .init(
                    type: "like",
                    score: 1,
                    createdAt: .unique,
                    updatedAt: .unique,
                    extraData: .defaultValue,
                    author: currentUser
                )
            ]
        )

        // Create previous message from another user with quoted message outside `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message6WithQuote: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: message5WithReactions.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup + 1)),
            quotedMessage: .mock(
                id: .unique,
                text: .unique,
                author: currentUser
            )
        )

        // Create previous message from current user which was deleted
        let message7Deleted: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: currentUser,
            createdAt: message6WithQuote.createdAt.addingTimeInterval(-minTimeIntervalBetweenMessagesInGroup),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        // Create previous thread root message from current
        let message8ThreadRoot: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: currentUser,
            createdAt: message7Deleted.createdAt.addingTimeInterval(-minTimeIntervalBetweenMessagesInGroup),
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, text: .unique, author: anotherUser)
            ],
            isSentByCurrentUser: true
        )

        // Create previous thread reply message from another user not shown in channel
        let message9ThreadReply: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: message8ThreadRoot.createdAt.addingTimeInterval(-minTimeIntervalBetweenMessagesInGroup),
            parentMessageId: .unique,
            showReplyInChannel: false
        )

        // Create previous thread reply message from another user shown in channel
        let message10ThreadReplyShownInChannel: ChatMessage = .mock(
            id: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: message9ThreadReply.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup - 1)),
            parentMessageId: .unique,
            showReplyInChannel: true
        )

        return [
            (message0WithLastActionFailed, true),
            (message1, false),
            (message2WithoutText, false),
            (message3, true),
            (message4, true),
            (message5WithReactions, false),
            (message6WithQuote, true),
            (message7Deleted, true),
            (message8ThreadRoot, false),
            (message9ThreadReply, true),
            (message10ThreadReplyShownInChannel, false)
        ]
    }
}
