//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
        let payload = self.payload.dictionary(
            with: .string(type.rawValue),
            forKey: AttachmentCodingKeys.type.rawValue
        )
        try payload.encode(to: encoder)
    }
}

extension MessageAttachmentPayload: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let attachmentType: AttachmentType
        if container.contains(.ogURL) {
            attachmentType = .linkPreview
        } else if let type = try container.decodeIfPresent(AttachmentType.self, forKey: .type) {
            attachmentType = type
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.ogURL,
                in: container,
                debugDescription: """
                Failed to indentify attachment type. Both `type` and `ogURL` are missing
                """
            )
        }

        guard
            let payload = try decoder
            .singleValueContainer()
            .decode(RawJSON.self)
            .dictionary(with: nil, forKey: AttachmentCodingKeys.type.rawValue)
        else {
            throw ClientError.AttachmentDecoding("Payload must be keyed container")
        }

        self.init(
            type: attachmentType,
            payload: payload
        )
    }
}
