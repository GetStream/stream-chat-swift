//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `ImageAttachmentPayload` payload type.
///
/// The `ChatMessageImageAttachment` attachment will be added to the message automatically
/// if the message was sent with attached `AnyAttachmentPayload` created with
/// local URL and `.image` attachment type.
public typealias ChatMessageImageAttachment = _ChatMessageAttachment<ImageAttachmentPayload>

/// Represents a payload for attachments with `.image` type.
public struct ImageAttachmentPayload: AttachmentPayload {
    /// An attachment type all `ImageAttachmentPayload` instances conform to. Is set to `.image`.
    public static let type: AttachmentType = .image

    /// A title, usually the name of the image.
    public let title: String?
    /// A link to the image.
    public internal(set) var imageURL: URL
    /// A link to the image preview.
    public let imagePreviewURL: URL
}

extension ImageAttachmentPayload: Equatable {}

// MARK: - Encodable

extension ImageAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encodeIfPresent(title, forKey: .fallback)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
    }
}

// MARK: - Decodable

extension ImageAttachmentPayload: Decodable {
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
