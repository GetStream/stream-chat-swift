//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias ChatMessageImageAttachment = _ChatMessageAttachment<AttachmentImagePayload>

public struct AttachmentImagePayload: AttachmentPayloadType {
    public static let type: AttachmentType = .image

    /// A title, usually the name of the image.
    public let title: String?
    /// A link to the image.
    public internal(set) var imageURL: URL
    /// A link to the image preview.
    public let imagePreviewURL: URL
}

extension AttachmentImagePayload: Equatable {}

// MARK: - Encodable

extension AttachmentImagePayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encodeIfPresent(title, forKey: .fallback)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
    }
}

// MARK: - Decodable

extension AttachmentImagePayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)

        guard
            let imageURL = (
                try container.decodeIfPresent(String.self, forKey: .image)
                    ?? container.decodeIfPresent(String.self, forKey: .imageURL)
                    ?? container.decodeIfPresent(String.self, forKey: .assetURL)
            )?.attachmentFixedURL
        else { throw ClientError.AttachmentDecoding() }
        
        let imagePreviewURL = try container
            .decodeIfPresent(String.self, forKey: .thumbURL)?
            .attachmentFixedURL

        let title = (
            try container.decodeIfPresent(String.self, forKey: .title) ??
                container.decodeIfPresent(String.self, forKey: .fallback) ??
                container.decodeIfPresent(String.self, forKey: .name)
        )?.trimmingCharacters(in: .whitespacesAndNewlines)

        self.init(
            title: title,
            imageURL: imageURL,
            imagePreviewURL: imagePreviewURL ?? imageURL
        )
    }
}
