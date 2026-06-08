//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

extension XCTestCase {
    static let channelCreatedDate = Date.unique
    static let channelUpdateDate = Date.unique

    // MARK: - Dummy data with extra data

    var dummyCurrentUser: OwnUserResponse {
        OwnUserResponse(
            id: "dummyCurrentUser",
            name: .unique,
            imageURL: nil,
            role: .user,
            teamsRole: nil,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: false,
            isBanned: false,
            language: nil,
            extraData: [:],
            pushPreference: nil
        )
    }

    var dummyUser: UserResponse {
        dummyUser(id: .unique)
    }

    func dummyUser(id: String) -> UserResponse {
        UserResponse(
            banned: true,
            blockedUserIds: [],
            createdAt: .unique,
            custom: [:],
            id: id,
            image: URL.unique().absoluteString,
            language: "",
            lastActive: .unique,
            name: .unique,
            online: true,
            role: UserRole.user.rawValue,
            teams: [],
            updatedAt: .unique
        )
    }

    func dummyMessagePayload(
        id: MessageId = .unique,
        cid: ChannelId? = nil,
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 60...900_000))
    ) -> MessageResponse {
        MessageResponse(
            attachments: [],
            cid: cid?.rawValue ?? "",
            createdAt: createdAt,
            custom: [:],
            deletedReplyCount: 0,
            html: "",
            id: id,
            latestReactions: [],
            mentionedChannel: false,
            mentionedHere: false,
            mentionedUsers: [dummyCurrentUser.asUserResponse()],
            ownReactions: [],
            pinned: false,
            reactionCounts: ["like": 1],
            reactionScores: ["like": 1],
            replyCount: 0,
            restrictedVisibility: [],
            shadowed: false,
            silent: false,
            text: .unique,
            type: MessageType.regular.rawValue,
            updatedAt: .unique,
            user: dummyUser
        )
    }

    func dummyPinnedMessagePayload(
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 50...99))
    ) -> MessageResponse {
        MessageResponse(
            attachments: [],
            cid: "",
            // createAt should be lower than dummyMessage, so it does not come first in `latestMessages`
            createdAt: createdAt,
            custom: [:],
            deletedReplyCount: 0,
            html: "",
            id: .unique,
            latestReactions: [],
            mentionedChannel: false,
            mentionedHere: false,
            mentionedUsers: [dummyCurrentUser.asUserResponse()],
            ownReactions: [],
            pinExpires: .unique,
            pinned: true,
            pinnedAt: .unique,
            pinnedBy: dummyUser,
            reactionCounts: ["like": 1],
            reactionScores: ["like": 1],
            replyCount: 0,
            restrictedVisibility: [],
            shadowed: false,
            silent: false,
            text: .unique,
            type: MessageType.regular.rawValue,
            updatedAt: .unique,
            user: dummyUser
        )
    }

    var dummyChannelRead: ReadStateResponse {
        .dummy(
            lastRead: Date(timeIntervalSince1970: 1),
            lastReadMessageId: .unique,
            unreadMessages: 10,
            user: dummyCurrentUser.asUserResponse()
        )
    }

    func dummyPayload(
        with channelId: ChannelId,
        name: String = .unique,
        numberOfMessages: Int = 1,
        members: [ChannelMemberResponse] = [.unique],
        watchers: [UserResponse]? = nil,
        includeMembership: Bool = true,
        messages: [MessageResponse]? = nil,
        pendingMessages: [MessageResponse]? = nil,
        pinnedMessages: [MessageResponse] = [],
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
            messageRemindersEnabled: true,
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
        filterTags: [String]? = nil,
        ownCapabilities: [String] = [],
        channelExtraData: [String: RawJSON] = [:],
        createdAt: Date = XCTestCase.channelCreatedDate,
        blocked: Bool? = false,
        hidden: Bool? = nil,
        truncatedAt: Date? = nil,
        cooldownDuration: Int? = nil,
        channelReads: [ReadStateResponse]? = nil,
        pushPreference: PushPreferencesResponse? = nil
    ) -> ChannelStateResponseFields {
        var payloadMessages: [MessageResponse] = []
        if let messages = messages {
            payloadMessages = messages
        } else {
            for _ in 0..<numberOfMessages {
                payloadMessages += [dummyMessagePayload()]
            }
        }

        let lastMessageAt: Date? = payloadMessages.map(\.createdAt).max()

        let detail = ChannelResponse.dummy(
            cid: channelId,
            name: name,
            imageURL: .unique(),
            extraData: channelExtraData,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: .unique,
            truncatedAt: truncatedAt,
            createdBy: dummyUser,
            config: channelConfig,
            filterTags: filterTags,
            ownCapabilities: ownCapabilities,
            isFrozen: true,
            isBlocked: blocked,
            isDisabled: false,
            isHidden: hidden,
            members: members,
            memberCount: 100,
            messageCount: 100,
            team: .unique,
            cooldownDuration: cooldownDuration ?? .random(in: 0...120)
        )

        return ChannelStateResponseFields.dummy(
            channel: detail,
            watcherCount: watchers?.count ?? 1,
            watchers: watchers ?? [dummyUser],
            members: members,
            membership: includeMembership ? members.first : nil,
            messages: payloadMessages,
            pendingMessages: pendingMessages ?? [],
            pinnedMessages: pinnedMessages,
            channelReads: channelReads ?? [dummyChannelRead],
            isHidden: false,
            draft: nil,
            activeLiveLocations: [],
            pushPreference: pushPreference
        )
    }

    var dummyMessageWithNoExtraData: MessageResponse {
        MessageResponse(
            attachments: [],
            cid: "",
            createdAt: .unique,
            custom: [:],
            deletedReplyCount: 0,
            html: "",
            id: .unique,
            latestReactions: [],
            mentionedChannel: false,
            mentionedHere: false,
            mentionedUsers: [],
            ownReactions: [],
            pinned: false,
            reactionCounts: [:],
            reactionScores: [:],
            replyCount: 0,
            restrictedVisibility: [],
            shadowed: false,
            silent: false,
            text: .unique,
            type: MessageType.regular.rawValue,
            updatedAt: .unique,
            user: dummyUser
        )
    }

    var dummyChannelReadWithNoExtraData: ReadStateResponse {
        .dummy(
            lastRead: .unique,
            lastReadMessageId: .unique,
            unreadMessages: .random(in: 0...10),
            user: dummyUser
        )
    }

    func dummyPayloadWithNoExtraData(with channelId: ChannelId) -> ChannelStateResponseFields {
        let member: ChannelMemberResponse =
            .dummy(
                user: .init(
                    banned: true,
                    blockedUserIds: [],
                    createdAt: .unique,
                    custom: [:],
                    id: .unique,
                    language: "",
                    lastActive: .unique,
                    name: .unique,
                    online: true,
                    role: UserRole.admin.rawValue,
                    teams: [],
                    updatedAt: .unique
                ),
                createdAt: .unique,
                updatedAt: .unique,
                role: .member
            )

        let detail = ChannelResponse.dummy(
            cid: channelId,
            name: .unique,
            imageURL: .unique(),
            extraData: [:],
            lastMessageAt: .unique,
            createdAt: .unique,
            deletedAt: .unique,
            updatedAt: .unique,
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
            isDisabled: false,
            isHidden: nil,
            members: [],
            memberCount: 100,
            messageCount: 100,
            team: .unique,
            cooldownDuration: .random(in: 0...120)
        )

        return ChannelStateResponseFields.dummy(
            channel: detail,
            watcherCount: 10,
            watchers: [dummyUser],
            members: [member],
            membership: member,
            messages: [dummyMessageWithNoExtraData],
            pinnedMessages: [dummyMessageWithNoExtraData],
            channelReads: [dummyChannelReadWithNoExtraData]
        )
    }

    func dummyThreadPayload(
        parentMessageId: MessageId = .unique,
        parentMessage: MessageResponse = .dummy(),
        channel: ChannelResponse = .dummy(),
        createdBy: UserResponse = .dummy(userId: .newUniqueId),
        replyCount: Int = 0,
        participantCount: Int = 0,
        activeParticipantCount: Int = 0,
        threadParticipants: [ThreadParticipantPayload] = [],
        lastMessageAt: Date? = .unique,
        createdAt: Date = .unique,
        updatedAt: Date? = .unique,
        title: String? = .unique,
        latestReplies: [MessageResponse] = [],
        read: [ReadStateResponse] = [],
        draft: DraftResponse? = nil,
        extraData: [String: RawJSON] = [:]
    ) -> ThreadStateResponse {
        .dummy(
            activeParticipantCount: activeParticipantCount,
            channel: channel,
            createdAt: createdAt,
            createdBy: createdBy,
            custom: extraData,
            draft: draft,
            lastMessageAt: lastMessageAt,
            latestReplies: latestReplies,
            parentMessage: parentMessage,
            parentMessageId: parentMessageId,
            participantCount: participantCount,
            read: read,
            replyCount: replyCount,
            threadParticipants: threadParticipants,
            title: title ?? "",
            updatedAt: updatedAt ?? createdAt
        )
    }

    func dummyThreadReadPayload(
        user: UserResponse = .dummy(userId: .unique),
        lastReadAt: Date? = .unique,
        unreadMessagesCount: Int = 0
    ) -> ReadStateResponse {
        .dummy(
            lastRead: lastReadAt ?? Date(timeIntervalSince1970: 0),
            unreadMessages: unreadMessagesCount,
            user: user
        )
    }

    func dummyThreadParticipantPayload(
        user: UserResponse = .dummy(userId: .unique),
        threadId: String = .unique,
        createdAt: Date = .unique,
        lastReadAt: Date? = .unique
    ) -> ThreadParticipantPayload {
        .init(
            appPk: 0,
            channelCid: "",
            createdAt: createdAt,
            custom: [:],
            lastReadAt: lastReadAt ?? Date(timeIntervalSince1970: 0),
            lastThreadMessageAt: nil,
            leftThreadAt: nil,
            threadId: threadId,
            user: user,
            userId: user.id
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
        latestAnswers: [PollVoteResponseData?]? = nil,
        options: [PollOptionResponseData?] = [],
        ownVotes: [PollVoteResponseData?] = [],
        custom: [String: RawJSON] = [:],
        latestVotesByOption: [String: [PollVoteResponseData]] = [:],
        voteCountsByOption: [String: Int] = [:],
        isClosed: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        votingVisibility: String? = nil,
        user: UserResponse? = .dummy(userId: .unique)
    ) -> PollResponseData {
        .init(
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            answersCount: answersCount,
            createdAt: createdAt,
            createdBy: user,
            createdById: user?.id ?? createdById,
            custom: custom,
            description: description,
            enforceUniqueVote: enforceUniqueVote,
            id: id,
            isClosed: isClosed,
            latestAnswers: latestAnswers?.compactMap { $0 } ?? [],
            latestVotesByOption: latestVotesByOption,
            maxVotesAllowed: maxVotesAllowed,
            name: name,
            options: options.compactMap { $0 },
            ownVotes: ownVotes.compactMap { $0 },
            updatedAt: updatedAt,
            voteCount: voteCount,
            voteCountsByOption: voteCountsByOption,
            votingVisibility: votingVisibility ?? ""
        )
    }
    
    func dummyPollOptionPayload(
        id: String = .unique,
        text: String = "Test Option",
        custom: [String: RawJSON] = [:]
    ) -> PollOptionResponseData {
        .init(
            custom: custom,
            id: id,
            text: text
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
        user: UserResponse? = .dummy(userId: .unique)
    ) -> PollVoteResponseData {
        .init(
            answerText: answerText,
            createdAt: createdAt,
            id: id,
            isAnswer: isAnswer,
            optionId: optionId ?? "",
            pollId: pollId,
            updatedAt: updatedAt,
            user: user,
            userId: userId
        )
    }
}

extension QueryPollsResponse {
    static func dummy(
        duration: String = "",
        next: String? = nil,
        polls: [PollResponseData] = [],
        prev: String? = nil
    ) -> QueryPollsResponse {
        .init(duration: duration, next: next, polls: polls, prev: prev)
    }
}

extension PollVoteResponse {
    static func dummy(
        duration: String = "",
        poll: PollResponseData? = nil,
        vote: PollVoteResponseData? = nil
    ) -> PollVoteResponse {
        .init(duration: duration, poll: poll, vote: vote)
    }
}

extension PollVotesResponse {
    static func dummy(
        duration: String = "",
        next: String? = nil,
        prev: String? = nil,
        votes: [PollVoteResponseData] = []
    ) -> PollVotesResponse {
        .init(duration: duration, next: next, prev: prev, votes: votes)
    }
}

private extension ChannelMemberResponse {
    static var unique: ChannelMemberResponse {
        withLastActivity(at: .unique)
    }

    static func withLastActivity(at date: Date) -> ChannelMemberResponse {
        let userId = String.unique
        return .dummy(
            user: UserResponse(
                banned: true,
                blockedUserIds: [],
                createdAt: .unique,
                custom: [:],
                id: userId,
                language: "",
                lastActive: date,
                name: .unique,
                online: true,
                role: UserRole.admin.rawValue,
                teams: [],
                updatedAt: .unique
            ),
            createdAt: .unique,
            updatedAt: .unique,
            role: .moderator
        )
    }
}

private extension UserResponse {
    static func withLastActivity(at date: Date) -> UserResponse {
        .init(
            banned: true,
            blockedUserIds: [],
            createdAt: .unique,
            custom: [:],
            id: .unique,
            language: "",
            lastActive: date,
            name: .unique,
            online: true,
            role: UserRole.admin.rawValue,
            teams: [],
            updatedAt: .unique
        )
    }
}
