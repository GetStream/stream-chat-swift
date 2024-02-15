//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

extension XCTestCase {
    static let channelCreatedDate = Date.unique
    static let channelUpdateDate = Date.unique

    // MARK: - Dummy data with extra data

    var dummyCurrentUser: OwnUser {
        OwnUser.dummy(userId: "dummyCurrentUser", role: .user)
    }

    var dummyUser: UserObject {
        dummyUser(id: .unique)
    }

    func dummyUser(id: String) -> UserObject {
        UserObject.dummy(userId: id)
    }

    func dummyMessagePayload(
        id: MessageId = .unique,
        cid: ChannelId? = nil,
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 60...900_000))
    ) -> Message {
        Message.dummy(
            messageId: id,
            createdAt: createdAt,
            cid: cid,
            reactionScores: ["like": 1], 
            reactionCounts: ["like": 1],
            mentionedUsers: [dummyUser]
        )
    }

    func dummyPinnedMessagePayload(
        createdAt: Date = XCTestCase.channelCreatedDate.addingTimeInterval(.random(in: 50...99))
    ) -> Message {
        Message.dummy(
            messageId: .unique,
            createdAt: createdAt,
            cid: .unique,
            pinned: true,
            pinnedByUserId: dummyUser.id,
            pinnedAt: .unique,
            pinExpires: .unique,
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            mentionedUsers: [dummyUser]
        )
    }

    var dummyChannelRead: Read {
        Read(lastRead: Date(timeIntervalSince1970: 1), unreadMessages: 10)
    }

    func dummyPayload(
        with channelId: ChannelId,
        numberOfMessages: Int = 1,
        members: [ChannelMember] = [.dummy()],
        watchers: [UserObject]? = nil,
        includeMembership: Bool = true,
        messages: [Message]? = nil,
        pinnedMessages: [Message] = [],
        channelConfig: ChannelConfig = .default,
        ownCapabilities: [String] = [],
        channelExtraData: [String: RawJSON] = [:],
        createdAt: Date = XCTestCase.channelCreatedDate,
        truncatedAt: Date? = nil,
        cooldownDuration: Int? = nil,
        channelReads: [Read]? = nil
    ) -> ChannelStateResponse {
        var payloadMessages: [Message] = []
        if let messages = messages {
            payloadMessages = messages
        } else {
            for _ in 0..<numberOfMessages {
                payloadMessages += [dummyMessagePayload()]
            }
        }

        let lastMessageAt: Date? = payloadMessages.map(\.createdAt).max()

        //TODO: expand the response
        let payload: ChannelStateResponse =
            .init(
                duration: "",
                members: members,
                messages: messages ?? [],
                pinnedMessages: pinnedMessages
            )

        return payload
    }

    var dummyMessageWithNoExtraData: Message {
        .dummy()
    }

    var dummyChannelReadWithNoExtraData: Read {
        Read(lastRead: Date(timeIntervalSince1970: 1), unreadMessages: .random(in: 0...10))
    }

    func dummyPayloadWithNoExtraData(with channelId: ChannelId) -> ChannelResponse {
        let payload: ChannelResponse = .dummy(cid: channelId)
        return payload
    }
}

private extension ChannelMember {
    static var unique: ChannelMember {
        withLastActivity(at: .unique)
    }

    static func withLastActivity(at date: Date) -> ChannelMember {
        let user = UserObject.dummy(userId: .unique, lastActive: date)
        return .dummy(user: user)
    }
}

private extension UserObject {
    static func withLastActivity(at date: Date) -> UserObject {
        .dummy(userId: .unique, lastActive: date)
    }
}

extension ChannelDatabaseSessionV2 {
    @discardableResult
    func saveChannel(
        payload: ChannelStateResponse,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO {
        try saveChannel(payload: payload.channel!, query: query, cache: cache)
    }
    
    @discardableResult
    func saveChannel(
        payload: ChannelStateResponse
    ) throws -> ChannelDTO {
        try saveChannel(payload: payload.channel!, query: nil, cache: nil)
    }
}

extension ChannelsResponse {
    init(channels: [ChannelStateResponse]) {
        self.init(duration: "", channels: channels.map(\.toResponseFields))
    }
}

extension OwnUser {
    var toUser: UserObject {
        UserObject(id: id, role: role)
    }
    
    var toMember: ChannelMember {
        ChannelMember.dummy(
            user: self.toUser,
            createdAt: .unique,
            updatedAt: .unique,
            lastActive: .unique,
            role: .init(rawValue: role),
            isMemberBanned: false
        )
    }
}
