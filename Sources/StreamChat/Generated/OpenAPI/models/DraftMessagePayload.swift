//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DraftMessagePayload: Sendable, Codable, JSONEncodable {
    /// Array of message attachments
    let attachments: [MessageAttachmentPayload]?
    let custom: [String: RawJSON]
    /// Message ID is unique string identifier of the message
    let id: String
    /// List of mentioned users
    let mentionedUsers: [UserPayload]?
    /// ID of parent message (thread)
    let parentId: String?
    /// Whether thread reply should be shown in the channel as well
    let showInChannel: Bool?
    /// Whether message is silent or not
    let silent: Bool?
    /// Text of the message
    let text: String

    init(
        attachments: [MessageAttachmentPayload]? = nil,
        custom: [String: RawJSON],
        id: String,
        mentionedUsers: [UserPayload]? = nil,
        parentId: String? = nil,
        showInChannel: Bool? = nil,
        silent: Bool? = nil,
        text: String
    ) {
        self.attachments = attachments
        self.custom = custom
        self.id = id
        self.mentionedUsers = mentionedUsers
        self.parentId = parentId
        self.showInChannel = showInChannel
        self.silent = silent
        self.text = text
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case custom
        case id
        case mentionedUsers = "mentioned_users"
        case parentId = "parent_id"
        case showInChannel = "show_in_channel"
        case silent
        case text
    }

    class var customExcludedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        attachments = try container.decodeIfPresent([MessageAttachmentPayload].self, forKey: .attachments)
        if let decoded = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) {
            custom = decoded
        } else {
            var flattened = try [String: RawJSON](from: decoder)
            flattened.removeValues(forKeys: Array(Self.customExcludedKeys))
            custom = flattened
        }
        id = try container.decode(String.self, forKey: .id)
        mentionedUsers = try container.decodeIfPresent([UserPayload].self, forKey: .mentionedUsers)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        showInChannel = try container.decodeIfPresent(Bool.self, forKey: .showInChannel)
        silent = try container.decodeIfPresent(Bool.self, forKey: .silent)
        text = try container.decode(String.self, forKey: .text)
    }
}
