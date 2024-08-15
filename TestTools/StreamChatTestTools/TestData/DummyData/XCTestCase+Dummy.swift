//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

extension XCTestCase {
    static let channelCreatedDate = Date.unique
    static let channelUpdateDate = Date.unique

    // MARK: - Dummy data with extra data

    var dummyCurrentUser: CurrentUserPayload {
        CurrentUserPayload(
            id: "dummyCurrentUser",
            name: .unique,
            imageURL: nil,
            role: .user,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: false,
            isBanned: false,
            language: nil,
            extraData: [:]
        )
    }

    var dummyUser: UserPayload {
        dummyUser(id: .unique)
    }

    func dummyUser(id: String) -> UserPayload {
        UserPayload(
            id: id,
            name: .unique,
            imageURL: .unique(),
            role: .user,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            language: nil,
            extraData: [:]
        )
    }

    func dummyMessagePayload(
        id: MessageId = .unique,
        cid: ChannelId? = nil,
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 60...900_000))
    ) -> MessagePayload {
        MessagePayload(
            id: id,
            cid: cid,
            type: .regular,
            user: dummyUser,
            createdAt: createdAt,
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: false,
            mentionedUsers: [dummyCurrentUser],
            replyCount: 0,
            extraData: [:],
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            isSilent: false,
            isShadowed: false,
            attachments: []
        )
    }

    func dummyPinnedMessagePayload(
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 50...99))
    ) -> MessagePayload {
        MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            // createAt should be lower than dummyMessage, so it does not come first in `latestMessages`
            createdAt: createdAt,
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: false,
            mentionedUsers: [dummyCurrentUser],
            replyCount: 0,
            extraData: [:],
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            isSilent: false,
            isShadowed: false,
            attachments: [],
            pinned: true,
            pinnedBy: dummyUser,
            pinnedAt: .unique,
            pinExpires: .unique
        )
    }

    var dummyChannelRead: ChannelReadPayload {
        ChannelReadPayload(user: dummyCurrentUser, lastReadAt: Date(timeIntervalSince1970: 1), lastReadMessageId: .unique, unreadMessagesCount: 10)
    }

    func dummyPayload(
        with channelId: ChannelId,
        name: String = .unique,
        numberOfMessages: Int = 1,
        members: [MemberPayload] = [.unique],
        watchers: [UserPayload]? = nil,
        includeMembership: Bool = true,
        messages: [MessagePayload]? = nil,
        pendingMessages: [MessagePayload]? = nil,
        pinnedMessages: [MessagePayload] = [],
        channelConfig: ChannelConfig = .init(
            reactionsEnabled: true,
            typingEventsEnabled: true,
            readEventsEnabled: true,
            connectEventsEnabled: true,
            uploadsEnabled: true,
            repliesEnabled: true,
            quotesEnabled: true,
            searchEnabled: true,
            mutesEnabled: true,
            urlEnrichmentEnabled: true,
            messageRetention: "1000",
            maxMessageLength: 100,
            commands: [
                .init(
                    name: "test",
                    description: "test commant",
                    set: "test",
                    args: "test"
                )
            ],
            createdAt: XCTestCase.channelCreatedDate,
            updatedAt: .unique
        ),
        ownCapabilities: [String] = [],
        channelExtraData: [String: RawJSON] = [:],
        createdAt: Date = XCTestCase.channelCreatedDate,
        truncatedAt: Date? = nil,
        cooldownDuration: Int? = nil,
        channelReads: [ChannelReadPayload]? = nil
    ) -> ChannelPayload {
        var payloadMessages: [MessagePayload] = []
        if let messages = messages {
            payloadMessages = messages
        } else {
            for _ in 0..<numberOfMessages {
                payloadMessages += [dummyMessagePayload()]
            }
        }

        let lastMessageAt: Date? = payloadMessages.map(\.createdAt).max()

        let payload: ChannelPayload =
            .init(
                channel: .init(
                    cid: channelId,
                    name: name,
                    imageURL: .unique(),
                    extraData: channelExtraData,
                    typeRawValue: channelId.type.rawValue,
                    lastMessageAt: lastMessageAt,
                    createdAt: createdAt,
                    deletedAt: nil,
                    updatedAt: .unique,
                    truncatedAt: truncatedAt,
                    createdBy: dummyUser,
                    config: channelConfig,
                    ownCapabilities: ownCapabilities,
                    isFrozen: true,
                    isBlocked: false,
                    isHidden: nil,
                    members: members,
                    memberCount: 100,
                    team: .unique,
                    cooldownDuration: cooldownDuration ?? .random(in: 0...120)
                ),
                watcherCount: watchers?.count ?? 1,
                watchers: watchers ?? [dummyUser],
                members: members,
                membership: includeMembership ? members.first : nil,
                messages: payloadMessages,
                pendingMessages: pendingMessages,
                pinnedMessages: pinnedMessages,
                channelReads: channelReads ?? [dummyChannelRead],
                isHidden: false
            )

        return payload
    }

    var dummyMessageWithNoExtraData: MessagePayload {
        MessagePayload(
            id: .unique,
            type: .regular,
            user: dummyUser,
            createdAt: .unique,
            updatedAt: .unique,
            deletedAt: nil,
            text: .unique,
            command: nil,
            args: nil,
            parentId: nil,
            showReplyInChannel: false,
            mentionedUsers: [],
            replyCount: 0,
            extraData: [:],
            reactionScores: [:],
            reactionCounts: [:],
            isSilent: false,
            isShadowed: false,
            attachments: []
        )
    }

    var dummyChannelReadWithNoExtraData: ChannelReadPayload {
        ChannelReadPayload(user: dummyUser, lastReadAt: .unique, lastReadMessageId: .unique, unreadMessagesCount: .random(in: 0...10))
    }

    func dummyPayloadWithNoExtraData(with channelId: ChannelId) -> ChannelPayload {
        let member: MemberPayload =
            .init(
                user: .init(
                    id: .unique,
                    name: .unique,
                    imageURL: nil,
                    role: .admin,
                    createdAt: .unique,
                    updatedAt: .unique,
                    deactivatedAt: nil,
                    lastActiveAt: .unique,
                    isOnline: true,
                    isInvisible: true,
                    isBanned: true,
                    teams: [],
                    language: nil,
                    extraData: [:]
                ),
                userId: .unique,
                role: .member,
                createdAt: .unique,
                updatedAt: .unique
            )

        let payload: ChannelPayload =
            .init(
                channel: .init(
                    cid: channelId,
                    name: .unique,
                    imageURL: .unique(),
                    extraData: [:],
                    typeRawValue: channelId.type.rawValue,
                    lastMessageAt: .unique,
                    createdAt: .unique,
                    deletedAt: .unique,
                    updatedAt: .unique,
                    truncatedAt: nil,
                    createdBy: dummyUser,
                    config: .init(
                        reactionsEnabled: true,
                        typingEventsEnabled: true,
                        readEventsEnabled: true,
                        connectEventsEnabled: true,
                        uploadsEnabled: true,
                        repliesEnabled: true,
                        quotesEnabled: true,
                        searchEnabled: true,
                        mutesEnabled: true,
                        urlEnrichmentEnabled: true,
                        messageRetention: "1000",
                        maxMessageLength: 100,
                        commands: [
                            .init(
                                name: "test",
                                description: "test commant",
                                set: "test",
                                args: "test"
                            )
                        ],
                        createdAt: XCTestCase.channelCreatedDate,
                        updatedAt: .unique
                    ),
                    ownCapabilities: [],
                    isFrozen: true,
                    isBlocked: false,
                    isHidden: nil,
                    members: nil,
                    memberCount: 100,
                    team: .unique,
                    cooldownDuration: .random(in: 0...120)
                ),
                watcherCount: 10,
                watchers: [dummyUser],
                members: [member],
                membership: member,
                messages: [dummyMessageWithNoExtraData],
                pendingMessages: nil,
                pinnedMessages: [dummyMessageWithNoExtraData],
                channelReads: [dummyChannelReadWithNoExtraData],
                isHidden: nil
            )

        return payload
    }

    func dummyThreadPayload(
        parentMessageId: MessageId = .unique,
        parentMessage: MessagePayload = .dummy(),
        channel: ChannelDetailPayload = .dummy(),
        createdBy: UserPayload = .dummy(userId: .newUniqueId),
        replyCount: Int = 0,
        participantCount: Int = 0,
        threadParticipants: [ThreadParticipantPayload] = [],
        lastMessageAt: Date? = .unique,
        createdAt: Date = .unique,
        updatedAt: Date? = .unique,
        title: String? = .unique,
        latestReplies: [MessagePayload] = [],
        read: [ThreadReadPayload] = [],
        extraData: [String: RawJSON] = [:]
    ) -> ThreadPayload {
        .init(
            parentMessageId: parentMessageId,
            parentMessage: parentMessage,
            channel: channel,
            createdBy: createdBy,
            replyCount: replyCount,
            participantCount: participantCount,
            threadParticipants: threadParticipants,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            latestReplies: latestReplies,
            read: read,
            extraData: extraData
        )
    }

    func dummyThreadReadPayload(
        user: UserPayload = .dummy(userId: .unique),
        lastReadAt: Date? = .unique,
        unreadMessagesCount: Int = 0
    ) -> ThreadReadPayload {
        .init(
            user: user,
            lastReadAt: lastReadAt,
            unreadMessagesCount: unreadMessagesCount
        )
    }

    func dummyThreadParticipantPayload(
        user: UserPayload = .dummy(userId: .unique),
        threadId: String = .unique,
        createdAt: Date = .unique,
        lastReadAt: Date? = .unique
    ) -> ThreadParticipantPayload {
        .init(
            user: user,
            threadId: threadId,
            createdAt: createdAt,
            lastReadAt: lastReadAt
        )
    }
    
    func dummyPollPayload(
        allowAnswers: Bool = false,
        allowUserSuggestedOptions: Bool = true,
        answersCount: Int = 0,
        createdAt: Date = Date(),
        createdById: String = .unique,
        description: String = "",
        enforceUniqueVote: Bool = false,
        id: String = .unique,
        name: String = "Test Poll",
        updatedAt: Date = Date(),
        voteCount: Int = 0,
        latestAnswers: [PollVotePayload?]? = nil,
        options: [PollOptionPayload?] = [],
        ownVotes: [PollVotePayload?] = [],
        custom: [String : RawJSON] = [:],
        latestVotesByOption: [String : [PollVotePayload]] = [:],
        voteCountsByOption: [String : Int] = [:],
        isClosed: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        votingVisibility: String? = nil,
        user: UserPayload? = .dummy(userId: .unique)
    ) -> PollPayload {
        .init(
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            answersCount: answersCount,
            createdAt: createdAt,
            createdById: user?.id ?? createdById,
            description: description,
            enforceUniqueVote: enforceUniqueVote,
            id: id,
            name: name,
            updatedAt: updatedAt,
            voteCount: voteCount,
            latestAnswers: latestAnswers,
            options: options,
            ownVotes: ownVotes,
            custom: custom,
            latestVotesByOption: latestVotesByOption,
            voteCountsByOption: voteCountsByOption,
            isClosed: isClosed,
            maxVotesAllowed: maxVotesAllowed,
            votingVisibility: votingVisibility,
            createdBy: user
        )
    }
    
    func dummyPollOptionPayload(
        id: String = .unique,
        text: String = "Test Option",
        custom: [String: RawJSON] = [:]
    ) -> PollOptionPayload {
        .init(
            id: id,
            text: text,
            custom: custom
        )
    }
    
    func dummyPollVotePayload(
        createdAt: Date = Date(),
        id: String = .unique,
        optionId: String? = nil,
        pollId: String = .unique,
        updatedAt: Date = Date(),
        answerText: String? = nil,
        isAnswer: Bool? = false,
        userId: String? = .unique,
        user: UserPayload? = .dummy(userId: .unique)
    ) -> PollVotePayload {
        .init(
            createdAt: createdAt,
            id: id,
            optionId: optionId,
            pollId: pollId,
            updatedAt: updatedAt,
            answerText: answerText,
            isAnswer: isAnswer,
            userId: userId,
            user: user
        )
    }
}

private extension MemberPayload {
    static var unique: MemberPayload {
        withLastActivity(at: .unique)
    }

    static func withLastActivity(at date: Date) -> MemberPayload {
        let userId = String.unique
        return .init(
            user: .init(
                id: userId,
                name: .unique,
                imageURL: nil,
                role: .admin,
                createdAt: .unique,
                updatedAt: .unique,
                deactivatedAt: nil,
                lastActiveAt: date,
                isOnline: true,
                isInvisible: true,
                isBanned: true,
                teams: [],
                language: nil, 
                extraData: [:]
            ),
            userId: userId,
            role: .moderator,
            createdAt: .unique,
            updatedAt: .unique
        )
    }
}

private extension UserPayload {
    static func withLastActivity(at date: Date) -> UserPayload {
        .init(
            id: .unique,
            name: .unique,
            imageURL: nil,
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: date,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            language: nil,
            extraData: [:]
        )
    }
}
