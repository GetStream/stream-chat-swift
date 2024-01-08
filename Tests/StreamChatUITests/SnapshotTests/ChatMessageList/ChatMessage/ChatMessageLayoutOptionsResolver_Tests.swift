//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageLayoutOptionsResolver_Tests: XCTestCase {
    private var appearance: Appearance = Appearance()

    // MARK: - Flipped

    func test_optionsForMessage_whenMessageIsSentByCurrentUser_includesFlipped() {
        let sut = createOptionsResolver()

        // Create a message sent NOT by the current user
        let messageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByCurrentUser]),
            appearance: appearance
        )

        // Assert `.flipped` is included
        XCTAssertTrue(layoutOptions.contains(.flipped))
    }

    func test_optionsForMessage_whenMessageIsSentNotByCurrentUser_doesNotIncludeFlipped() {
        let sut = createOptionsResolver()

        // Create a message sent by another current user
        let messageSentNotByCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentNotByCurrentUser]),
            appearance: appearance
        )

        // Assert `.flipped` is not included
        XCTAssertFalse(layoutOptions.contains(.flipped))
    }

    // MARK: - Bubble

    func test_optionsForMessage_includesBubbleByDefault() {
        let sut = createOptionsResolver()

        let channelHistory: [(ChatMessage, Bool)] = .directMessagesHistory(
            minTimeIntervalBetweenMessagesInGroup: sut.maxTimeIntervalBetweenMessagesInGroup
        )

        for message in channelHistory.map(\.0) {
            // Calculate layout options for the current message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([message]),
                appearance: appearance
            )

            // Assert `.bubble` is included
            XCTAssertTrue(layoutOptions.contains(.bubble))
        }
    }

    // MARK: - Continuous bubble

    func test_optionsForMessage_whenMessageIsLastInSequence_doesNotIncludeContinuousBubble() {
        let sut = createOptionsResolver()

        for isSentByCurrentUser in [true, false] {
            // Create message
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Calculate layout options for the message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([message]),
                appearance: appearance
            )

            // Assert `.continuousBubble` is not included
            XCTAssertFalse(layoutOptions.contains(.continuousBubble))
        }
    }

    func test_optionsForMessage_whenMessageIsNotLastInSequence_includesContinuousBubble() {
        let sut = createOptionsResolver()

        // Create a user
        let user: ChatUser = .mock(id: .unique)

        for isSentByCurrentUser in [true, false] {
            // Create a message
            let message1: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: user,
                createdAt: Date(),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Create a previous message sent by the same user within `minTimeIntervalBetweenMessagesInGroup` timeframe
            let message2: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: user,
                createdAt: message1.createdAt.addingTimeInterval(
                    -(sut.maxTimeIntervalBetweenMessagesInGroup - 1)
                ),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Calculate layout options for the second message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 1, section: 0),
                in: .mock(cid: .unique),
                with: .init([message1, message2]),
                appearance: appearance
            )

            // Assert `.continuousBubble` is included
            XCTAssertTrue(layoutOptions.contains(.continuousBubble))
        }
    }

    func test_optionsForMessage_whenMessageBelongsToThread_includesContinuousBubble() {
        let sut = createOptionsResolver()

        // Create non-deleted thread root message
        let messageThreadRoot: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, cid: .unique, text: .unique, author: .mock(id: .unique))
            ]
        )

        // Create non-deleted thread part message
        let messageThreadPart: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: messageThreadRoot.id
        )

        for threadMessage in [messageThreadRoot, messageThreadPart] {
            // Calculate layout options for the message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([threadMessage]),
                appearance: appearance
            )

            // Assert `.continuousBubble` is included
            XCTAssertTrue(layoutOptions.contains(.continuousBubble))
        }
    }

    // MARK: - Avatar size padding

    func test_optionsForMessage_whenMessageIsSentByCurrentUser_doesNotIncludeAvatarSizePadding() {
        let sut = createOptionsResolver()

        // Create non-deleted message sent by current user
        let messageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByCurrentUser]),
            appearance: appearance
        )

        // Assert `.avatarSizePadding` is not included since the message is sent by current user
        XCTAssertFalse(layoutOptions.contains(.avatarSizePadding))
    }

    func test_optionsForMessage_whenMessageSentByAnotherUserIsNotLastInSequence_includesAvatarSizePadding() {
        let sut = createOptionsResolver()

        // Create a user
        let anotherUser: ChatUser = .mock(id: .unique)

        // Create last message from another user
        let messageFromAnotherUser1: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: Date(),
            isSentByCurrentUser: false
        )

        // Create message from another user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let messageFromAnotherUser2: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: messageFromAnotherUser1.createdAt.addingTimeInterval(
                -(sut.maxTimeIntervalBetweenMessagesInGroup - 1)
            ),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the second message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 1, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageFromAnotherUser1, messageFromAnotherUser2]),
            appearance: appearance
        )

        // Assert `.avatarSizePadding` is included
        XCTAssertTrue(layoutOptions.contains(.avatarSizePadding))
    }

    func test_optionsForMessage_whenMessageSentByAnotherUserIsLastInSequence_includesAvatarSizePadding() {
        let sut = createOptionsResolver()

        // Create ephemeral message sent by another user
        let messageSentByAnotherUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByAnotherUser]),
            appearance: appearance
        )

        // Assert `.avatarSizePadding` is not included since for the last message the avatar is shown
        XCTAssertFalse(layoutOptions.contains(.avatarSizePadding))
    }

    // MARK: - Timestamp

    func test_optionsForMessage_whenMessageIsLastInSequence_includesTimestamp() {
        let sut = createOptionsResolver()

        for isSentByCurrentUser in [true, false] {
            // Create message
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Calculate layout options for the message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([message]),
                appearance: appearance
            )

            // Assert `.timestamp` is included
            XCTAssertTrue(layoutOptions.contains(.timestamp))
        }
    }

    func test_optionsForMessage_whenMessageIsNotLastInSequence_doesNotIncludeTimestamp() {
        let sut = createOptionsResolver()

        // Create a user
        let user: ChatUser = .mock(id: .unique)

        for isSentByCurrentUser in [true, false] {
            // Create a message
            let message1: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: user,
                createdAt: Date(),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Create a previous message sent by the same user within `minTimeIntervalBetweenMessagesInGroup` timeframe
            let message2: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: user,
                createdAt: message1.createdAt.addingTimeInterval(
                    -(sut.maxTimeIntervalBetweenMessagesInGroup - 1)
                ),
                isSentByCurrentUser: isSentByCurrentUser
            )

            // Calculate layout options for the second message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 1, section: 0),
                in: .mock(cid: .unique),
                with: .init([message1, message2]),
                appearance: appearance
            )

            // Assert `.timestamp` is not included since the message is not the last in sequence
            XCTAssertFalse(layoutOptions.contains(.timestamp))
        }
    }

    // MARK: - Only visible for current user

    func test_optionsForMessage_whenMessageIsNotSentByCurrentUser_doesNotIncludeOnlyVisibleToYouIndicator() {
        let sut = createOptionsResolver()

        // Create ephemeral message sent by another user
        let messageSentByAnotherUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByAnotherUser]),
            appearance: appearance
        )

        // Assert `.onlyVisibleToYouIndicator` is included
        XCTAssertFalse(layoutOptions.contains(.onlyVisibleToYouIndicator))
    }

    func test_optionsForMessage_whenMessageSentByCurrentUserIsEphemeral_includesOnlyVisibleToYouIndicator() {
        let sut = createOptionsResolver()

        // Create ephemeral message sent by current user
        let ephemeralMessageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([ephemeralMessageSentByCurrentUser]),
            appearance: appearance
        )

        // Assert `.onlyVisibleToYouIndicator` is included
        XCTAssertTrue(layoutOptions.contains(.onlyVisibleToYouIndicator))
    }

    func test_optionsForMessage_whenMessageSentByTheCurrentUserIsDeleted_includesOnlyVisibleToYouIndicator() {
        let sut = createOptionsResolver(deletedMessagesVisibility: .visibleForCurrentUser)

        // Create ephemeral message sent by current user
        let deletedMessageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .deleted,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessageSentByCurrentUser]),
            appearance: appearance
        )

        // Assert `.onlyVisibleToYouIndicator` is included
        XCTAssertTrue(layoutOptions.contains(.onlyVisibleToYouIndicator))
    }

    func test_optionsForMessage_whenMessageSentByTheCurrentUserIsDeleted_doesNotIncludeOnlyVisibleToYouIndicator() {
        // Create ephemeral message sent by current user
        let deletedMessageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .deleted,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        for deletedMessagesVisibility in [ChatClientConfig.DeletedMessageVisibility.alwaysVisible, .alwaysHidden] {
            let sut = createOptionsResolver(deletedMessagesVisibility: deletedMessagesVisibility)

            // Calculate layout options for the message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([deletedMessageSentByCurrentUser]),
                appearance: appearance
            )

            // Assert `.onlyVisibleToYouIndicator` is not included
            XCTAssertFalse(layoutOptions.contains(.onlyVisibleToYouIndicator))
        }
    }

    // MARK: - Text

    func test_optionsForMessage_whenMessageIsEphemeral_doesNotIncludeText() {
        let sut = createOptionsResolver()

        // Create ephemeral message
        let ephemeralMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique)
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([ephemeralMessage]),
            appearance: appearance
        )

        // Assert `.text` is not included
        XCTAssertFalse(layoutOptions.contains(.text))
    }

    func test_optionsForMessage_whenMessageIsDeleted_includesText() {
        let sut = createOptionsResolver()

        // Create deleted message
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessage]),
            appearance: appearance
        )

        // Assert `.text` is included
        XCTAssertTrue(layoutOptions.contains(.text))
    }

    func test_optionsForMessage_whenMessageHasText_includesText() {
        let sut = createOptionsResolver()

        // Create non-ephemeral non-deleted message with text
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique)
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([message]),
            appearance: appearance
        )

        // Assert `.text` is included
        XCTAssertTrue(layoutOptions.contains(.text))
    }

    // MARK: - Avatar

    func test_optionsForMessage_whenDeletedMessageSentByAnotherUserIsLastInSequence_includesAvatar() {
        let sut = createOptionsResolver()

        // Create deleted message last in sequence by another user
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: false
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessage]),
            appearance: appearance
        )

        // Assert `.avatar` is included
        XCTAssertTrue(layoutOptions.contains(.avatar))
    }

    func test_optionsForMessage_whenMessageIsSentByCurrentUser_doesNotIncludeAvatar() {
        let sut = createOptionsResolver()

        // Create non-deleted message sent by current user that ends the sequence
        let messageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageSentByCurrentUser]),
            appearance: appearance
        )

        // Assert `.avatar` is not included since the message is sent by current user
        XCTAssertFalse(layoutOptions.contains(.avatar))
    }

    func test_optionsForMessage_whenMessageSentByAnotherUserIsNotLastInSequence_doesNotIncludeAvatar() {
        let sut = createOptionsResolver()

        // Create a user
        let anotherUser: ChatUser = .mock(id: .unique)

        // Create last message from current user
        let messageFromAnotherUser1: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: Date(),
            isSentByCurrentUser: false
        )

        // Create message from current user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let messageFromAnotherUser2: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: messageFromAnotherUser1.createdAt.addingTimeInterval(
                -(sut.maxTimeIntervalBetweenMessagesInGroup - 1)
            ),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the second message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 1, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageFromAnotherUser1, messageFromAnotherUser2]),
            appearance: appearance
        )

        // Assert `.avatar` is not included since the message is not the sequence end
        XCTAssertFalse(layoutOptions.contains(.avatar))
    }

    func test_optionsForMessage_whenMessageSentByAnotherUserIsLastInSequence_includesAvatar() {
        let sut = createOptionsResolver()

        // Create a user
        let anotherUser: ChatUser = .mock(id: .unique)

        // Create last message from current user
        let messageFromAnotherUser1: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: Date(),
            isSentByCurrentUser: false
        )

        // Create message from current user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let messageFromAnotherUser2: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: messageFromAnotherUser1.createdAt.addingTimeInterval(
                -(sut.maxTimeIntervalBetweenMessagesInGroup - 1)
            ),
            isSentByCurrentUser: false
        )

        // Calculate layout options for the last message in sequence
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageFromAnotherUser1, messageFromAnotherUser2]),
            appearance: appearance
        )

        // Assert `.avatar` is included
        XCTAssertTrue(layoutOptions.contains(.avatar))
    }

    // MARK: - Author name

    func test_optionsForMessage_whenDeletedMessageSentByAnotherUserIsLastInSequence_includesAuthorName() {
        let sut = createOptionsResolver()

        // Create deleted message
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: false
        )

        // Create a channel where > 2 members can be
        let notDMChannel: ChatChannel = .mock(
            cid: .init(type: .livestream, id: .unique),
            memberCount: 5
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: notDMChannel,
            with: .init([deletedMessage]),
            appearance: appearance
        )

        // Assert `.authorName` is included
        XCTAssertTrue(layoutOptions.contains(.authorName))
    }

    func test_optionsForMessage_whenMessageIsSentByCurrentUser_doesNotIncludeAuthorName() {
        let sut = createOptionsResolver()

        // Create non-deleted message sent by current user
        let messageSentByCurrentUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        // Create a channel where > 2 members can be
        let notDMChannel: ChatChannel = .mock(
            cid: .init(type: .livestream, id: .unique),
            memberCount: 5
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: notDMChannel,
            with: .init([messageSentByCurrentUser]),
            appearance: appearance
        )

        // Assert `.authorName` is not included since the message is sent by current user
        XCTAssertFalse(layoutOptions.contains(.authorName))
    }

    func test_optionsForMessage_whenMessageIsNotLastInSequence_doesNotIncludeAuthorName() {
        let sut = createOptionsResolver()

        // Create a user
        let anotherUser: ChatUser = .mock(id: .unique)

        // Create last message from current user
        let messageFromAnotherUser1: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: Date(),
            isSentByCurrentUser: false
        )

        // Create message from current user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let messageFromAnotherUser2: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: messageFromAnotherUser1.createdAt.addingTimeInterval(
                -(sut.maxTimeIntervalBetweenMessagesInGroup - 1)
            ),
            isSentByCurrentUser: false
        )

        // Create a channel where > 2 members can be
        let notDMChannel: ChatChannel = .mock(
            cid: .init(type: .livestream, id: .unique),
            memberCount: 5
        )

        // Calculate layout options for the second message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 1, section: 0),
            in: notDMChannel,
            with: .init([messageFromAnotherUser1, messageFromAnotherUser2]),
            appearance: appearance
        )

        // Assert `.authorName` is not included since the message is not the sequence end
        XCTAssertFalse(layoutOptions.contains(.authorName))
    }

    func test_optionsForMessage_whenChannelIsDirectMessaging_doesNotIncludeAuthorName() {
        let sut = createOptionsResolver()

        // Create last message from current user
        let messageFromAnotherUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Create a DM channel
        let directMessagesChannel: ChatChannel = .mockDMChannel(
            memberCount: 2
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: directMessagesChannel,
            with: .init([messageFromAnotherUser]),
            appearance: appearance
        )

        // Assert `.authorName` is not included since the channel is DM
        XCTAssertFalse(layoutOptions.contains(.authorName))
    }

    func test_optionsForMessage_whenMessageEndsTheSequenceSentByAnotherUserAndChannelIsNotDM_includesAuthorName() {
        let sut = createOptionsResolver()

        // Create last message from current user
        let messageFromAnotherUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        // Create a channel where > 2 members can be
        let notDMChannel: ChatChannel = .mock(
            cid: .init(type: .livestream, id: .unique),
            memberCount: 5
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: notDMChannel,
            with: .init([messageFromAnotherUser]),
            appearance: appearance
        )

        // Assert `.authorName` is included
        XCTAssertTrue(layoutOptions.contains(.authorName))
    }

    // MARK: - Quoted message

    func test_optionsForMessage_whenMessageHasQuotedMessage_includesQuotedMessage() {
        let sut = createOptionsResolver()

        // Create non-deleted message with quoted message
        let messageWithQuotedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            quotedMessage: .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique)
            )
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([messageWithQuotedMessage]),
            appearance: appearance
        )

        // Assert `.quotedMessage` is included
        XCTAssertTrue(layoutOptions.contains(.quotedMessage))
    }

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeQuotedMessage() {
        let sut = createOptionsResolver()

        // Create deleted message with quoted message
        let deletedMessageWithQuotedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            quotedMessage: .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique)
            )
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessageWithQuotedMessage]),
            appearance: appearance
        )

        // Assert `.quotedMessage` is not included because message is deleted
        XCTAssertFalse(layoutOptions.contains(.quotedMessage))
    }

    // MARK: - Thread info

    func test_optionsForMessage_whenMessageBelongsToThread_includesThreadInfo() {
        let sut = createOptionsResolver()

        // Create non-deleted thread root message
        let messageThreadRoot: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, cid: .unique, text: .unique, author: .mock(id: .unique))
            ]
        )

        // Create non-deleted thread part message
        let messageThreadPart: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: messageThreadRoot.id
        )

        for threadMessage in [messageThreadRoot, messageThreadPart] {
            // Calculate layout options for the message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([threadMessage]),
                appearance: appearance
            )

            // Assert `.threadInfo` is included
            XCTAssertTrue(layoutOptions.contains(.threadInfo))
        }
    }

    func test_optionsForMessage_whenMessageIsDeleted_includesThreadInfo() {
        let sut = createOptionsResolver()

        // Create deleted thread root message
        let messageThreadRoot: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, cid: .unique, text: .unique, author: .mock(id: .unique))
            ]
        )

        // Create deleted thread part message
        let messageThreadPart: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            parentMessageId: messageThreadRoot.id
        )

        for threadMessage in [messageThreadRoot, messageThreadPart] {
            // Calculate layout options for the message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([threadMessage]),
                appearance: appearance
            )

            // Assert `.threadInfo` is not included since message is deleted
            XCTAssertTrue(layoutOptions.contains(.threadInfo))
        }
    }

    func test_optionsForMessage_whenRepliesEnabled_includesThreadInfo() {
        let sut = createOptionsResolver()

        // Create deleted thread root message
        let messageThreadRoot: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, cid: .unique, text: .unique, author: .mock(id: .unique))
            ]
        )

        // Create deleted thread part message
        let messageThreadPart: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: messageThreadRoot.id
        )

        for threadMessage in [messageThreadRoot, messageThreadPart] {
            // Calculate layout options for the message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique, config: .mock(repliesEnabled: true)),
                with: .init([threadMessage]),
                appearance: appearance
            )

            XCTAssertTrue(layoutOptions.contains(.threadInfo))
        }
    }

    func test_optionsForMessage_whenRepliesDisabled_doesNotIncludeThreadInfo() {
        let sut = createOptionsResolver()

        // Create deleted thread root message
        let messageThreadRoot: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, cid: .unique, text: .unique, author: .mock(id: .unique))
            ]
        )

        // Create deleted thread part message
        let messageThreadPart: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            parentMessageId: messageThreadRoot.id
        )

        for threadMessage in [messageThreadRoot, messageThreadPart] {
            // Calculate layout options for the message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique, config: .mock(repliesEnabled: false)),
                with: .init([threadMessage]),
                appearance: appearance
            )

            XCTAssertFalse(layoutOptions.contains(.threadInfo))
        }
    }

    // MARK: - Reactions

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeReactions() {
        let sut = createOptionsResolver()

        // Create deleted message with reactions
        let deletedMessageWithReactions: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
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
                    author: .mock(id: .unique),
                    extraData: [:]
                )
            ]
        )

        // Create channel with enabled reactions
        let channelWithReactionsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(reactionsEnabled: true)
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channelWithReactionsEnabled,
            with: .init([deletedMessageWithReactions]),
            appearance: appearance
        )

        // Assert `.reactions` is not included since message is deleted
        XCTAssertFalse(layoutOptions.contains(.reactions))
    }

    func test_optionsForMessage_whenMessageHasUnhandledReactionsAndChannelEnablesReactions_doesNotIncludeReactions() {
        let sut = createOptionsResolver()

        // Create non-deleted message with reactions
        let messageWithReactions: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            reactionScores: ["like": 1],
            latestReactions: [
                .init(
                    type: "surfing",
                    score: 1,
                    createdAt: .unique,
                    updatedAt: .unique,
                    author: .mock(id: .unique),
                    extraData: [:]
                )
            ]
        )

        // Create channel with enabled reactions
        let channelWithReactionsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(reactionsEnabled: true)
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channelWithReactionsEnabled,
            with: .init([messageWithReactions]),
            appearance: appearance
        )

        // Assert `.reactions` is not included
        XCTAssertFalse(layoutOptions.contains(.reactions))
    }

    func test_optionsForMessage_whenMessageHasReactionsAndChannelEnablesReactions_includesReactions() {
        let sut = createOptionsResolver()

        // Create non-deleted message with reactions
        let messageWithReactions: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            reactionScores: ["like": 1],
            latestReactions: [
                .init(
                    type: "like",
                    score: 1,
                    createdAt: .unique,
                    updatedAt: .unique,
                    author: .mock(id: .unique),
                    extraData: [:]
                )
            ]
        )

        // Create channel with enabled reactions
        let channelWithReactionsEnabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(reactionsEnabled: true)
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channelWithReactionsEnabled,
            with: .init([messageWithReactions]),
            appearance: appearance
        )

        // Assert `.reactions` is included
        XCTAssertTrue(layoutOptions.contains(.reactions))
    }

    func test_optionsForMessage_whenMessageHasReactionsButChannelDisablesReactions_doesNotIncludesReactions() {
        let sut = createOptionsResolver()

        // Create non-deleted message with reactions
        let messageWithReactions: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            reactionScores: ["like": 1],
            latestReactions: [
                .init(
                    type: "like",
                    score: 1,
                    createdAt: .unique,
                    updatedAt: .unique,
                    author: .mock(id: .unique),
                    extraData: [:]
                )
            ]
        )

        // Create channel with disabled reactions
        let channelWithReactionsDisabled: ChatChannel = .mock(
            cid: .unique,
            config: .mock(reactionsEnabled: false)
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channelWithReactionsDisabled,
            with: .init([messageWithReactions]),
            appearance: appearance
        )

        // Assert `.reactions` is not included
        XCTAssertFalse(layoutOptions.contains(.reactions))
    }

    func test_optionsForMessage_whenMessageHasNoReactions_doesNotIncludeReactions() {
        let sut = createOptionsResolver()

        // Create non-deleted message without reactions
        let messageWithoutReactions: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
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
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channelWithReactionsEnabled,
            with: .init([messageWithoutReactions]),
            appearance: appearance
        )

        // Assert `.reactions` is not included
        XCTAssertFalse(layoutOptions.contains(.reactions))
    }

    // MARK: - Error indicator

    func test_optionsForMessage_whenMessageHasFailedState_includesErrorIndicator() {
        let sut = createOptionsResolver()

        for failedState: LocalMessageState in [.sendingFailed, .syncingFailed, .deletingFailed] {
            // Create non-deleted message with failed local state
            let messageWithFailedState: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                deletedAt: nil,
                localState: failedState,
                isSentByCurrentUser: true
            )

            // Calculate layout options for the message
            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: .mock(cid: .unique),
                with: .init([messageWithFailedState]),
                appearance: appearance
            )

            // Assert `.errorIndicator` is included
            XCTAssertTrue(layoutOptions.contains(.errorIndicator))
        }
    }

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeErrorIndicator() {
        let sut = createOptionsResolver()

        // Create deleted message
        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([deletedMessage]),
            appearance: appearance
        )

        // Assert `.errorIndicator` is not included
        XCTAssertFalse(layoutOptions.contains(.errorIndicator))
    }

    func test_optionsForMessage_whenMessageIsSystem() {
        let sut = createOptionsResolver()

        let systemMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .system,
            author: .mock(id: .unique),
            deletedAt: .unique
        )

        // Calculate layout options for the message
        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([systemMessage]),
            appearance: appearance
        )

        // Assert only `.text` AND `.centered` is included in the options
        XCTAssertTrue(layoutOptions == [.text, .centered])
    }

    // MARK: - isMessageLastInSequence

    func test_isMessageLastInSequence() {
        let sut = createOptionsResolver()

        // Get mock channel history
        let testCases: [(ChatMessage, Bool)] = .directMessagesHistory(
            minTimeIntervalBetweenMessagesInGroup: sut.maxTimeIntervalBetweenMessagesInGroup
        )

        // Iterate test cases
        for (index, testCase) in testCases.enumerated() {
            // Get the expected value
            let isStandaloneOrLastInSequence = testCase.1

            // Assert the actual value matches the expected one.
            XCTAssertEqual(
                sut.isMessageLastInSequence(
                    messageIndexPath: .init(item: index, section: 0),
                    messages: .init(testCases.map(\.0))
                ),
                isStandaloneOrLastInSequence
            )
        }
    }

    func test_isMessageLastInSequence_whenTheNextMessageFromTheSameUserIsErrorMessage_returnsTrue() {
        let sut = createOptionsResolver()

        let cid: ChannelId = .unique
        let author: ChatUser = .mock(id: .unique)

        let messageFollowedByErrorMessage: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: .unique,
            author: author
        )

        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: .unique,
            type: .error,
            author: author,
            createdAt: messageFollowedByErrorMessage.createdAt.addingTimeInterval(1)
        )

        XCTAssertTrue(
            sut.isMessageLastInSequence(
                messageIndexPath: .init(item: 1, section: 0),
                messages: .init([deletedMessage, messageFollowedByErrorMessage])
            )
        )
    }

    func test_isMessageLastInSequence_whenNextMessageFromSameUserIsEphemeral_returnsTrue() {
        let sut = createOptionsResolver()

        let cid: ChannelId = .unique
        let author: ChatUser = .mock(id: .unique)

        let messageFollowedByEphemeralMessage: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: .unique,
            author: author
        )

        let ephemeralMessage: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: .unique,
            type: .ephemeral,
            author: author,
            createdAt: messageFollowedByEphemeralMessage.createdAt.addingTimeInterval(1)
        )

        XCTAssertTrue(
            sut.isMessageLastInSequence(
                messageIndexPath: .init(item: 1, section: 0),
                messages: .init([ephemeralMessage, messageFollowedByEphemeralMessage])
            )
        )
    }

    func test_isMessageLastInSequence_whenNextMessageFromSameUserIsSystem_returnsTrue() {
        let sut = createOptionsResolver()

        let cid: ChannelId = .unique
        let author: ChatUser = .mock(id: .unique)

        let messageFollowedBySystemMessage: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: .unique,
            author: author
        )

        let systemMessage: ChatMessage = .mock(
            id: .unique,
            cid: cid,
            text: "Luke was removed from the channel",
            type: .system,
            author: author,
            createdAt: messageFollowedBySystemMessage.createdAt.addingTimeInterval(1)
        )

        XCTAssertTrue(
            sut.isMessageLastInSequence(
                messageIndexPath: .init(item: 1, section: 0),
                messages: .init([systemMessage, messageFollowedBySystemMessage])
            )
        )
    }

    // MARK: - showOnlyVisibleToYouIndicator

    func test_showOnlyVisibleToYouIndicator_whenMessageIsSentByAnotherUser_returnsFalse() {
        let sut = createOptionsResolver()

        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .deleted,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: false
        )

        XCTAssertFalse(sut.showOnlyVisibleToYouIndicator(for: message))
    }

    func test_showOnlyVisibleToYouIndicator_whenMessageIsEphemeralAndSentByCurrentUser_returnsTrue() {
        let sut = createOptionsResolver()

        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            isSentByCurrentUser: true
        )

        XCTAssertTrue(sut.showOnlyVisibleToYouIndicator(for: message))
    }

    func test_showOnlyVisibleToYouIndicator_whenMessageIsDeletedAndSentByCurrentUser_returnsTrue() {
        let sut = createOptionsResolver(deletedMessagesVisibility: .visibleForCurrentUser)

        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .deleted,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        XCTAssertTrue(sut.showOnlyVisibleToYouIndicator(for: message))
    }

    func test_showOnlyVisibleToYouIndicator_whenMessageIsDeletedAndSentByCurrentUser_returnsFalse() {
        let message: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        for deletedMessagesVisibility in [ChatClientConfig.DeletedMessageVisibility.alwaysVisible, .alwaysHidden] {
            let sut = createOptionsResolver(deletedMessagesVisibility: deletedMessagesVisibility)

            XCTAssertFalse(sut.showOnlyVisibleToYouIndicator(for: message))
        }
    }

    func test_showOnlyVisibleToYouIndicator_whenMessageNotDeletedAndSentByCurrentUser_returnsFalse() {
        let sut = createOptionsResolver(deletedMessagesVisibility: .visibleForCurrentUser)

        for type in [MessageType.regular, .reply, .system, .error] {
            let message: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                type: type,
                author: .mock(id: .unique),
                deletedAt: .unique,
                isSentByCurrentUser: true
            )

            XCTAssertFalse(sut.showOnlyVisibleToYouIndicator(for: message))
        }
    }

    // MARK: - Delivery status

    func test_optionsForMessage_whenMessageIsSentByAnotherUser_doesNotIncludeDeliveryStatusIndicator() {
        let sut = createOptionsResolver()

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let messageSentByAnotherUser: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: .mock(id: .unique),
            isSentByCurrentUser: false
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([messageSentByAnotherUser]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.deliveryStatusIndicator))
    }

    func test_optionsForMessage_whenMessageIsDeleted_doesNotIncludeDeliveryStatusIndicator() {
        let sut = createOptionsResolver()

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let deletedMessage: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            type: .deleted,
            author: .mock(id: .unique),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([deletedMessage]),
            appearance: appearance
        )

        // Assert `.deliveryStatusIndicator` is not included
        XCTAssertFalse(layoutOptions.contains(.deliveryStatusIndicator))
    }

    func test_optionsForMessage_whenLastMessageActionIsFailed_doesNotIncludeDeliveryStatusIndicator() {
        let sut = createOptionsResolver()

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        for failedState: LocalMessageState in [.sendingFailed, .syncingFailed, .deletingFailed] {
            let messageWithFailedState: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                deletedAt: nil,
                localState: failedState,
                isSentByCurrentUser: true
            )

            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: channel,
                with: .init([messageWithFailedState]),
                appearance: appearance
            )

            XCTAssertFalse(layoutOptions.contains(.deliveryStatusIndicator))
        }
    }

    func test_optionsForMessage_whenHasPendingLocalState_includesDeliveryStatusIndicator() {
        let sut = createOptionsResolver()

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        for pendingState: LocalMessageState in [.pendingSend, .sending, .pendingSync, .syncing, .deleting] {
            let messageInPendingState: ChatMessage = .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: .mock(id: .unique),
                deletedAt: nil,
                localState: pendingState,
                isSentByCurrentUser: true
            )

            let layoutOptions = sut.optionsForMessage(
                at: .init(item: 0, section: 0),
                in: channel,
                with: .init([messageInPendingState]),
                appearance: appearance
            )

            XCTAssertTrue(layoutOptions.contains(.deliveryStatusIndicator))
        }
    }

    func test_optionsForMessage_whenMessageExistsRemotelyAndReadEventsEnabled_includesDeliveryStatusIndicator() {
        let sut = createOptionsResolver()

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: nil,
            localState: nil,
            isSentByCurrentUser: true
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertTrue(layoutOptions.contains(.deliveryStatusIndicator))
    }

    func test_optionsForMessage_whenMessageExistsRemotelyAndReadEventsDisabled_doesNotIncludeDeliveryStatusIndicator() {
        let sut = createOptionsResolver()

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: false)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            deletedAt: nil,
            localState: nil,
            isSentByCurrentUser: true
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.deliveryStatusIndicator))
    }

    func test_optionsForMessage_whenMessageIsEphemeral_doesNotIncludeDeliveryStatusIndicator() {
        let sut = createOptionsResolver()

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true)
        )

        let ephemeralMessage: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            type: .ephemeral,
            author: .mock(id: .unique),
            deletedAt: nil,
            localState: nil,
            isSentByCurrentUser: true
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([ephemeralMessage]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.deliveryStatusIndicator))
    }

    func test_optionsForMessage_whenMessageAutoTranslatedEnabled_whenShouldRenderTranslation_thenIncludesTranslationOption() {
        let sut = createOptionsResolver()
        sut.components = .mock
        sut.components?.messageAutoTranslationEnabled = true

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            membership: .mock(id: .unique, language: .portuguese)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            text: "Hello",
            translations: [.portuguese: "Olá"],
            originalLanguage: .english
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertTrue(layoutOptions.contains(.translation))
    }

    func test_optionsForMessage_whenMessageAutoTranslatedDisabled_whenShouldRenderTranslation_thenDoesNotIncludeTranslationOption() {
        let sut = createOptionsResolver()
        sut.components = .mock
        sut.components?.messageAutoTranslationEnabled = false

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            membership: .mock(id: .unique, language: .portuguese)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            text: "Hello",
            translations: [.portuguese: "Olá"],
            originalLanguage: .english
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.translation))
    }

    func test_optionsForMessage_whenNoTranslations_thenDoesNotIncludeTranslationOption() {
        let sut = createOptionsResolver()
        sut.components = .mock
        sut.components?.messageAutoTranslationEnabled = true

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            membership: .mock(id: .unique, language: .portuguese)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            text: "Hello",
            translations: nil,
            originalLanguage: .english
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.translation))
    }

    func test_optionsForMessage_whenCurrentUserTranslationNotAvailable_thenDoesNotIncludeTranslationOption() {
        let sut = createOptionsResolver()
        sut.components = .mock
        sut.components?.messageAutoTranslationEnabled = true

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            membership: .mock(id: .unique, language: .portuguese)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            text: "Hello",
            translations: [.french: "Bonjour"],
            originalLanguage: .english
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.translation))
    }

    func test_optionsForMessage_whenMessageHasNoTranslation_thenDoesNotIncludeTranslationOption() {
        let sut = createOptionsResolver()
        sut.components = .mock
        sut.components?.messageAutoTranslationEnabled = true

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            membership: .mock(id: .unique, language: .portuguese)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            text: "Asd",
            translations: [.portuguese: "Asd"],
            originalLanguage: .english
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.translation))
    }

    func test_optionsForMessage_whenShouldRenderTranslation_whenMessageIsDeleted_thenDoesNotIncludeTranslationOption() {
        let sut = createOptionsResolver()
        sut.components = .mock
        sut.components?.messageAutoTranslationEnabled = true

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            membership: .mock(id: .unique, language: .portuguese)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            text: "Hello",
            deletedAt: .unique,
            translations: [.portuguese: "Olá"],
            originalLanguage: .english
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.translation))
    }

    func test_optionsForMessage_whenShouldRenderTranslation_whenMessageHasCommand_thenDoesNotIncludeTranslationOption() {
        let sut = createOptionsResolver()
        sut.components = .mock
        sut.components?.messageAutoTranslationEnabled = true

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            membership: .mock(id: .unique, language: .portuguese)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            text: "Hello",
            command: "giphy",
            translations: [.portuguese: "Olá"],
            originalLanguage: .english
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.translation))
    }

    func test_optionsForMessage_whenShouldRenderTranslation_whenMessageIsEmpty_thenDoesNotIncludeTranslationOption() {
        let sut = createOptionsResolver()
        sut.components = .mock
        sut.components?.messageAutoTranslationEnabled = true

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            membership: .mock(id: .unique, language: .portuguese)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            text: "",
            translations: [.portuguese: "Olá"],
            originalLanguage: .english
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.translation))
    }

    func test_optionsForMessage_whenShouldRenderTranslation_whenMessageLanguageIsTheSameHasOriginal_thenDoesNotIncludeTranslationOption() {
        let sut = createOptionsResolver()
        sut.components = .mock
        sut.components?.messageAutoTranslationEnabled = true

        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            membership: .mock(id: .unique, language: .portuguese)
        )

        let message: ChatMessage = .mock(
            id: .unique,
            text: "Olaaaa",
            translations: [.portuguese: "Olá"],
            originalLanguage: .portuguese
        )

        let layoutOptions = sut.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        XCTAssertFalse(layoutOptions.contains(.translation))
    }

    // MARK: - Helpers

    private func createOptionsResolver(
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility = .alwaysVisible
    ) -> ChatMessageLayoutOptionsResolver {
        var config = ChatClientConfig(apiKey: .init(.unique))
        config.deletedMessagesVisibility = deletedMessagesVisibility

        let resolver = ChatMessageLayoutOptionsResolver()
        resolver.config = config
        return resolver
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
            cid: .unique,
            text: .unique,
            author: currentUser,
            createdAt: Date(),
            localState: .syncingFailed,
            isSentByCurrentUser: true
        )

        // Create previous message from current user within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message1: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: currentUser,
            createdAt: message0WithLastActionFailed.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup - 1)),
            isSentByCurrentUser: true
        )

        // Create previous message from current user sent within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message2WithoutText: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: "",
            author: currentUser,
            createdAt: message1.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup - 1)),
            isSentByCurrentUser: true
        )

        // Create previous message from current user sent outside `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message3: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: currentUser,
            createdAt: message2WithoutText.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup + 1)),
            isSentByCurrentUser: true
        )

        // Create previous message from another user within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message4: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: message3.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup - 1))
        )

        // Create previous message from another user with reactions within `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message5WithReactions: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
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
                    author: currentUser,
                    extraData: [:]
                )
            ]
        )

        // Create previous message from another user with quoted message outside `minTimeIntervalBetweenMessagesInGroup` timeframe
        let message6WithQuote: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: message5WithReactions.createdAt.addingTimeInterval(-(minTimeIntervalBetweenMessagesInGroup + 1)),
            quotedMessage: .mock(
                id: .unique,
                cid: .unique,
                text: .unique,
                author: currentUser
            )
        )

        // Create previous message from current user which was deleted
        let message7Deleted: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: currentUser,
            createdAt: message6WithQuote.createdAt.addingTimeInterval(-minTimeIntervalBetweenMessagesInGroup),
            deletedAt: .unique,
            isSentByCurrentUser: true
        )

        // Create previous thread root message from current
        let message8ThreadRoot: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: currentUser,
            createdAt: message7Deleted.createdAt.addingTimeInterval(-minTimeIntervalBetweenMessagesInGroup),
            replyCount: 10,
            latestReplies: [
                .mock(id: .unique, cid: .unique, text: .unique, author: anotherUser)
            ],
            isSentByCurrentUser: true
        )

        // Create previous thread reply message from another user not shown in channel
        let message9ThreadReply: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
            text: .unique,
            author: anotherUser,
            createdAt: message8ThreadRoot.createdAt.addingTimeInterval(-minTimeIntervalBetweenMessagesInGroup),
            parentMessageId: .unique,
            showReplyInChannel: false
        )

        // Create previous thread reply message from another user shown in channel
        let message10ThreadReplyShownInChannel: ChatMessage = .mock(
            id: .unique,
            cid: .unique,
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
