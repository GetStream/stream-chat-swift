//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type that describes attachment JSON payload.
struct MessageAttachmentPayload {
    private enum CodingKeys: String, CodingKey {
        case type
        case ogURL = "og_scrape_url"
    }

    /// An attachment type.
    let type: AttachmentType
    /// A raw attachment payload data.
    /// It's possible to have attachments of custom type with unknown structure
    /// so we need to keep in raw data form so it will be possible to decode later.
    let payload: RawJSON
}

extension MessageAttachmentPayload: Encodable {
    func encode(to encoder: Encoder) throws {
        var payload = self.payload
        payload[AttachmentCodingKeys.type.rawValue] = .string(type.rawValue)
        try payload.encode(to: encoder)
    }
}

extension MessageAttachmentPayload: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let attachmentType: AttachmentType = try {
            if container.contains(.ogURL) {
                // Existence of `ogURL` means the attachment was obtained from the link sent within the message text.
                // We treat such attachment as of `.linkPreview` type.
                return .linkPreview
            } else if let type = try container.decodeIfPresent(AttachmentType.self, forKey: .type) {
                // If payload contains explicit type - take it!
                return type
            } else {
                // The `type` field will become a mandatory one time. We use `.unknown` type
                // to avoid having `type` optional until it is fixed on the backend side.
                return .unknown
            }
        }()

        var payload = try decoder.singleValueContainer().decode(RawJSON.self)

        guard payload.dictionaryValue != nil else {
            throw ClientError.AttachmentDecoding("Payload must be keyed container")
        }

        payload[AttachmentCodingKeys.type.rawValue] = nil

        self.init(
            type: attachmentType,
            payload: payload
        )
    }
}
