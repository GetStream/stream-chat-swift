//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: false,
            isBanned: false,
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
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: [:]
        )
    }
    
    func dummyMessagePayload(
        id: MessageId = .unique,
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 60...900_000))
    ) -> MessagePayload {
        MessagePayload(
            id: id,
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
        ChannelReadPayload(user: dummyCurrentUser, lastReadAt: Date(timeIntervalSince1970: 1), unreadMessagesCount: 10)
    }
    
    func dummyPayload(
        with channelId: ChannelId,
        numberOfMessages: Int = 1,
        members: [MemberPayload] = [.unique],
        watchers: [UserPayload]? = nil,
        includeMembership: Bool = true,
        messages: [MessagePayload]? = nil,
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
        channelExtraData: [String: RawJSON] = [:],
        truncatedAt: Date? = nil,
        cooldownDuration: Int? = nil
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
                    name: .unique,
                    imageURL: .unique(),
                    extraData: channelExtraData,
                    typeRawValue: channelId.type.rawValue,
                    lastMessageAt: lastMessageAt,
                    createdAt: XCTestCase.channelCreatedDate,
                    deletedAt: nil,
                    updatedAt: .unique,
                    truncatedAt: truncatedAt,
                    createdBy: dummyUser,
                    config: channelConfig,
                    isFrozen: true,
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
                pinnedMessages: pinnedMessages,
                channelReads: [dummyChannelRead],
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
        ChannelReadPayload(user: dummyUser, lastReadAt: .unique, unreadMessagesCount: .random(in: 0...10))
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
                    lastActiveAt: .unique,
                    isOnline: true,
                    isInvisible: true,
                    isBanned: true,
                    teams: [],
                    extraData: [:]
                ),
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
                    isFrozen: true,
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
                pinnedMessages: [dummyMessageWithNoExtraData],
                channelReads: [dummyChannelReadWithNoExtraData],
                isHidden: nil
            )
        
        return payload
    }
}

private extension MemberPayload {
    static var unique: MemberPayload {
        withLastActivity(at: .unique)
    }
    
    static func withLastActivity(at date: Date) -> MemberPayload {
        .init(
            user: .init(
                id: .unique,
                name: .unique,
                imageURL: nil,
                role: .admin,
                createdAt: .unique,
                updatedAt: .unique,
                lastActiveAt: date,
                isOnline: true,
                isInvisible: true,
                isBanned: true,
                teams: [],
                extraData: [:]
            ),
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
            lastActiveAt: date,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: [:]
        )
    }
}
