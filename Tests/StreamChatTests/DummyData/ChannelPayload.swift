//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

extension ChannelDetailPayload {
    /// Returns a dummy channel detail payload with the given cid
    static func dummy(cid: ChannelId) -> ChannelDetailPayload {
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
                role: .moderator,
                createdAt: .unique,
                updatedAt: .unique
            )
        
        let channelCreatedDate = Date.unique
        let lastMessageAt: Date? = Bool.random() ? channelCreatedDate.addingTimeInterval(.random(in: 100_000...900_000)) : nil
        
        return .init(
            cid: cid,
            name: .unique,
            imageURL: .unique(),
            extraData: [:],
            typeRawValue: cid.type.rawValue,
            lastMessageAt: lastMessageAt,
            createdAt: channelCreatedDate,
            deletedAt: nil,
            updatedAt: .unique,
            createdBy: .dummy(userId: .unique),
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
                        description: "test command",
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
            members: [member],
            cooldownDuration: .random(in: 0...120)
        )
    }
}
