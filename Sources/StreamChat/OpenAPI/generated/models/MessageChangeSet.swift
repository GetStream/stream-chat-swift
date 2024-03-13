//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageChangeSet: Codable, Hashable {
    public var attachments: Bool
    public var custom: Bool
    public var html: Bool
    public var mentionedUserIds: Bool
    public var mml: Bool
    public var pin: Bool
    public var quotedMessageId: Bool
    public var silent: Bool
    public var text: Bool

    public init(attachments: Bool, custom: Bool, html: Bool, mentionedUserIds: Bool, mml: Bool, pin: Bool, quotedMessageId: Bool, silent: Bool, text: Bool) {
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
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
