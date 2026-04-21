//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageChangeSet: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var attachments: Bool
    var custom: Bool
    var html: Bool
    var mentionedUserIds: Bool
    var mml: Bool
    var pin: Bool
    var quotedMessageId: Bool
    var silent: Bool
    var text: Bool

    init(attachments: Bool, custom: Bool, html: Bool, mentionedUserIds: Bool, mml: Bool, pin: Bool, quotedMessageId: Bool, silent: Bool, text: Bool) {
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

    static func == (lhs: MessageChangeSet, rhs: MessageChangeSet) -> Bool {
        lhs.attachments == rhs.attachments &&
            lhs.custom == rhs.custom &&
            lhs.html == rhs.html &&
            lhs.mentionedUserIds == rhs.mentionedUserIds &&
            lhs.mml == rhs.mml &&
            lhs.pin == rhs.pin &&
            lhs.quotedMessageId == rhs.quotedMessageId &&
            lhs.silent == rhs.silent &&
            lhs.text == rhs.text
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachments)
        hasher.combine(custom)
        hasher.combine(html)
        hasher.combine(mentionedUserIds)
        hasher.combine(mml)
        hasher.combine(pin)
        hasher.combine(quotedMessageId)
        hasher.combine(silent)
        hasher.combine(text)
    }
}
