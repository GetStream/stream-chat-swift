//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageRequest: Codable, Hashable {
    public var id: String? = nil
    public var parentId: String? = nil
    public var pinExpires: Date? = nil
    public var pinned: Bool? = nil
    public var pinnedAt: Date? = nil
    public var quotedMessageId: String? = nil
    public var showInChannel: Bool? = nil
    public var silent: Bool? = nil
    public var text: String? = nil
    public var type: String? = nil
    public var attachments: [AttachmentRequest?]? = nil
    public var mentionedUsers: [String]? = nil
    public var custom: [String: RawJSON]? = nil

    public init(id: String? = nil, parentId: String? = nil, pinExpires: Date? = nil, pinned: Bool? = nil, pinnedAt: Date? = nil, quotedMessageId: String? = nil, showInChannel: Bool? = nil, silent: Bool? = nil, text: String? = nil, type: String? = nil, attachments: [AttachmentRequest?]? = nil, mentionedUsers: [String]? = nil, custom: [String: RawJSON]? = nil) {
        self.id = id
        self.parentId = parentId
        self.pinExpires = pinExpires
        self.pinned = pinned
        self.pinnedAt = pinnedAt
        self.quotedMessageId = quotedMessageId
        self.showInChannel = showInChannel
        self.silent = silent
        self.text = text
        self.type = type
        self.attachments = attachments
        self.mentionedUsers = mentionedUsers
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case parentId = "parent_id"
        case pinExpires = "pin_expires"
        case pinned
        case pinnedAt = "pinned_at"
        case quotedMessageId = "quoted_message_id"
        case showInChannel = "show_in_channel"
        case silent
        case text
        case type
        case attachments
        case mentionedUsers = "mentioned_users"
        case custom
    }
}
