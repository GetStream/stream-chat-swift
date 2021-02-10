//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing an attachment of type `link`.
/// More info about enriched `URLs` can be found here:
/// https://getstream.io/chat/docs/node/message_format/?language=swift#attachment-format
public struct ChatMessageLinkAttachment: ChatMessageAttachment, AttachmentEnvelope, Decodable {
    public var type: AttachmentType { .link(underlyingType) }
    /// A main asset type of the enriched `URL`. Could be `audio`, `video`, `image`.
    let underlyingType: String?
    /// A unique identifier of the attachment.
    public var id: AttachmentId?
    /// An original `URL` that was enriched.
    public let ogURL: URL?
    /// A title (e.g video name in case of enriched `YouTube` link or song name in case of `Spotify` link).
    public let title: String?
    /// A text, usually description of the link content.
    public let text: String?
    /// An author, usually the link origin. (e.g. `YouTube`, `Spotify`)
    public let author: String?
    /// A link for displaying an attachment.
    /// Can be different from the original link, depends on the enriching rules.
    public let titleLink: URL?
    /// An image.
    public let imageURL: URL?
    /// A preview image.
    public let thumbURL: URL?
    /// A `URL` for an asset this link points to.
    public let assetURL: URL?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        ogURL = try container.decode(String.self, forKey: .ogURL).attachmentFixedURL
        author = try container.decodeIfPresent(String.self, forKey: .author)
        text = try container.decodeIfPresent(String.self, forKey: .text)?.trimmingCharacters(in: .whitespacesAndNewlines)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)?.attachmentFixedURL
        thumbURL = try container.decodeIfPresent(String.self, forKey: .thumbURL)?.attachmentFixedURL
        assetURL = try container.decodeIfPresent(String.self, forKey: .assetURL)?.attachmentFixedURL
        titleLink = try container.decodeIfPresent(String.self, forKey: .titleLink)?.attachmentFixedURL
        title = try container.decodeIfPresent(String.self, forKey: .title)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        underlyingType = try container.decodeIfPresent(String.self, forKey: .type)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(ogURL, forKey: .ogURL)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(thumbURL, forKey: .thumbURL)
        try container.encodeIfPresent(titleLink, forKey: .titleLink)
    }
}
