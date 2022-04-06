//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension ChannelDetailPayload {
    /// Returns dummy channel detail payload with the given values.
    static func dummy(
        cid: ChannelId = .unique,
        name: String? = .unique,
        imageURL: URL? = .unique(),
        extraData: [String: RawJSON] = [:],
        lastMessageAt: Date? = nil,
        createdAt: Date = .init(),
        deletedAt: Date? = nil,
        updatedAt: Date = .init(),
        truncatedAt: Date? = nil,
        createdBy: UserPayload = .dummy(userId: .unique),
        config: ChannelConfig = .mock(),
        isFrozen: Bool = false,
        isHidden: Bool? = nil,
        members: [MemberPayload] = [],
        team: String? = nil,
        cooldownDuration: Int = 0
    ) -> Self {
        .init(
            cid: cid,
            name: name,
            imageURL: imageURL,
            extraData: extraData,
            typeRawValue: cid.type.rawValue,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            deletedAt: deletedAt,
            updatedAt: updatedAt,
            truncatedAt: truncatedAt,
            createdBy: createdBy,
            config: config,
            isFrozen: isFrozen,
            isHidden: isHidden,
            members: members,
            memberCount: members.count,
            team: team,
            cooldownDuration: cooldownDuration
        )
    }
}
