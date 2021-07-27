//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

extension XCTestCase {
    static let channelCreatedDate = Date.unique

    // MARK: - Dummy data with extra data
    
    var dummyCurrentUser: CurrentUserPayload<NoExtraData> {
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
            extraData: .defaultValue,
            extraDataMap: [:]
        )
    }
    
    var dummyUser: UserPayload<NoExtraData> {
        dummyUser(id: .unique)
    }
    
    func dummyUser(id: String) -> UserPayload<NoExtraData> {
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
            extraData: .defaultValue,
            extraDataMap: [:]
        )
    }
    
    func dummyMessagePayload(
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 60...900_000))
    ) -> MessagePayload<NoExtraData> {
        MessagePayload(
            id: .unique,
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
            extraData: .defaultValue,
            extraDataMap: [:],
            reactionScores: ["like": 1],
            isSilent: false,
            attachments: []
        )
    }
    
    func dummyPinnedMessagePayload(
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 50...99))
    ) -> MessagePayload<NoExtraData> {
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
            extraData: .defaultValue,
            extraDataMap: [:],
            reactionScores: ["like": 1],
            isSilent: false,
            attachments: [],
            pinned: true,
            pinnedBy: dummyUser,
            pinnedAt: .unique,
            pinExpires: .unique
        )
    }
    
    var dummyChannelRead: ChannelReadPayload<NoExtraData> {
        ChannelReadPayload(user: dummyCurrentUser, lastReadAt: Date(timeIntervalSince1970: 1), unreadMessagesCount: 10)
    }
    
    func dummyPayload(
        with channelId: ChannelId,
        numberOfMessages: Int = 1,
        members: [MemberPayload<NoExtraData>] = [.unique],
        watchers: [UserPayload<NoExtraData>]? = nil,
        includeMembership: Bool = true,
        messages: [MessagePayload<NoExtraData>]? = nil,
        pinnedMessages: [MessagePayload<NoExtraData>] = [],
        channelConfig: ChannelConfig = .init(
            reactionsEnabled: true,
            typingEventsEnabled: true,
            readEventsEnabled: true,
            connectEventsEnabled: true,
            uploadsEnabled: true,
            repliesEnabled: true,
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
        )
    ) -> ChannelPayload<NoExtraData> {
        var payloadMessages: [MessagePayload<NoExtraData>] = []
        if let messages = messages {
            payloadMessages = messages
        } else {
            for _ in 0..<numberOfMessages {
                payloadMessages += [dummyMessagePayload()]
            }
        }
        
        let lastMessageAt: Date? = payloadMessages.map(\.createdAt).max()
        
        let payload: ChannelPayload<NoExtraData> =
            .init(
                channel: .init(
                    cid: channelId,
                    name: .unique,
                    imageURL: .unique(),
                    extraData: .defaultValue,
                    extraDataMap: [:],
                    typeRawValue: channelId.type.rawValue,
                    lastMessageAt: lastMessageAt,
                    createdAt: XCTestCase.channelCreatedDate,
                    deletedAt: nil,
                    updatedAt: .unique,
                    createdBy: dummyUser,
                    config: channelConfig,
                    isFrozen: true,
                    memberCount: 100,
                    team: .unique,
                    members: members,
                    cooldownDuration: .random(in: 0...120)
                ),
                watcherCount: watchers?.count ?? 1,
                watchers: watchers ?? [dummyUser],
                members: members,
                membership: includeMembership ? members.first : nil,
                messages: payloadMessages,
                pinnedMessages: pinnedMessages,
                channelReads: [dummyChannelRead]
            )
        
        return payload
    }
    
    // MARK: - Dummy data with no extra data
    
    enum NoExtraDataTypes: ExtraDataTypes {
        typealias Channel = NoExtraData
        typealias Message = NoExtraData
        typealias User = NoExtraData
        typealias Attachment = NoExtraData
    }
    
    var dummyMessageWithNoExtraData: MessagePayload<NoExtraDataTypes> {
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
            extraData: NoExtraData(),
            extraDataMap: [:],
            reactionScores: [:],
            isSilent: false,
            attachments: []
        )
    }
    
    var dummyChannelReadWithNoExtraData: ChannelReadPayload<NoExtraDataTypes> {
        ChannelReadPayload(user: dummyUser, lastReadAt: .unique, unreadMessagesCount: .random(in: 0...10))
    }
    
    func dummyPayloadWithNoExtraData(with channelId: ChannelId) -> ChannelPayload<NoExtraDataTypes> {
        let member: MemberPayload<NoExtraData> =
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
                    extraData: .init(),
                    extraDataMap: [:]
                ),
                role: .member,
                createdAt: .unique,
                updatedAt: .unique
            )
        
        let payload: ChannelPayload<NoExtraDataTypes> =
            .init(
                channel: .init(
                    cid: channelId,
                    name: .unique,
                    imageURL: .unique(),
                    extraData: .init(),
                    extraDataMap: [:],
                    typeRawValue: channelId.type.rawValue,
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
                    memberCount: 100,
                    team: .unique,
                    members: nil,
                    cooldownDuration: .random(in: 0...120)
                ),
                watcherCount: 10,
                watchers: [dummyUser],
                members: [member],
                membership: member,
                messages: [dummyMessageWithNoExtraData],
                pinnedMessages: [dummyMessageWithNoExtraData],
                channelReads: [dummyChannelReadWithNoExtraData]
            )
        
        return payload
    }
}

private extension MemberPayload where ExtraData == NoExtraData {
    static var unique: MemberPayload<NoExtraData> {
        withLastActivity(at: .unique)
    }
    
    static func withLastActivity(at date: Date) -> MemberPayload<NoExtraData> {
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
                extraData: .defaultValue,
                extraDataMap: [:]
            ),
            role: .moderator,
            createdAt: .unique,
            updatedAt: .unique
        )
    }
}

private extension UserPayload where ExtraData == NoExtraData {
    static func withLastActivity(at date: Date) -> UserPayload<NoExtraData> {
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
            extraData: .defaultValue,
            extraDataMap: [:]
        )
    }
}
