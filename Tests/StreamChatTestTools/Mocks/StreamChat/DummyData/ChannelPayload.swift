//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ChannelDetailPayload {
    /// Returns a dummy channel detail payload with the given cid
    static func dummy(
        cid: ChannelId,
        members: [MemberPayload] = [.dummy()],
        truncatedAt: Date? = nil
    ) -> ChannelDetailPayload {
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
            truncatedAt: truncatedAt,
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
            members: members,
            cooldownDuration: .random(in: 0...120)
        )
    }
}
