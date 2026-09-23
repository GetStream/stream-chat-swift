//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageChangeSet: Sendable, Decodable {
    let attachments: Bool
    let custom: Bool
    let html: Bool
    let mentionedUserIds: Bool
    let mml: Bool
    let pin: Bool
    let quotedMessageId: Bool
    let silent: Bool
    let text: Bool

    init(
        attachments: Bool,
        custom: Bool,
        html: Bool,
        mentionedUserIds: Bool,
        mml: Bool,
        pin: Bool,
        quotedMessageId: Bool,
        silent: Bool,
        text: Bool
    ) {
        self.attachments = attachments
        self.custom = custom
        self.html = html
        self.mentionedUserIds = mentionedUserIds
        self.mml = mml
        self.pin = pin
        self.quotedMessageId = quotedMessageId
        self.silent = silent
        self.text = text
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case custom
        case html
        case mentionedUserIds = "mentioned_user_ids"
        case mml
        case pin
        case quotedMessageId = "quoted_message_id"
        case silent
        case text
    }
}
