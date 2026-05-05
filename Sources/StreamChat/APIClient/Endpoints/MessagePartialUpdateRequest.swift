//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct MessagePartialUpdateRequest: Encodable {
    var set: SetProperties?
    var unset: [String]?
    var skipEnrichUrl: Bool?
    var userId: String?
    var user: UserRequestBody?

    /// The available message properties that can be updated.
    struct SetProperties: Encodable {
        var pinned: Bool?
        var text: String?
        var extraData: [String: RawJSON]?
        var attachments: [MessageAttachmentPayload]?

        enum CodingKeys: String, CodingKey {
            case text
            case pinned
            case extraData
            case attachments
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(text, forKey: .text)
            try container.encodeIfPresent(pinned, forKey: .pinned)
            try container.encodeIfPresent(attachments, forKey: .attachments)
            try extraData?.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        try container.encodeIfPresent(skipEnrichUrl, forKey: .skipEnrichUrl)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(set, forKey: .set)
        try container.encodeIfPresent(unset, forKey: .unset)
    }
}
