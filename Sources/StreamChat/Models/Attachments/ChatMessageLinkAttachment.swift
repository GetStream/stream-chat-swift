//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `LinkAttachmentPayload` payload type.
///
/// The `ChatMessageLinkAttachment` attachment will be added to the message automatically
/// if the message is sent with the text containing the URL.
public typealias ChatMessageLinkAttachment = ChatMessageAttachment<LinkAttachmentPayload>

/// Represents a payload for attachments with `.linkPreview` type.
public struct LinkAttachmentPayload: AttachmentPayload {
    /// An attachment type all `LinkAttachmentPayload` instances conform to. Is set to `.linkPreview`.
    public static let type: AttachmentType = .linkPreview

    /// An original `URL` that was included into the message text and then enriched.
    public var originalURL: URL
    /// A title (e.g video name in case of enriched `YouTube` link or song name in case of `Spotify` link).
    public var title: String?
    /// A text, usually description of the link content.
    public var text: String?
    /// An author, usually the link origin. (e.g. `YouTube`, `Spotify`)
    public var author: String?
    /// A link for displaying an attachment.
    /// Can be different from the original link, depends on the enriching rules.
    public var titleLink: URL?
    // A link for navigating to url. This computed fallbacks to `titleLink` or `originalURL` and enriches it with URL scheme if needed.
    // e.g "google.com" -> "http://google.com"
    public var url: URL {
        titleLink?.enrichedURL ?? originalURL.enrichedURL
    }

    /// An image.
    public var assetURL: URL?
    /// A preview image URL.
    public var previewURL: URL?

    public init(
        originalURL: URL,
        title: String? = nil,
        text: String? = nil,
        author: String? = nil,
        titleLink: URL? = nil,
        assetURL: URL? = nil,
        previewURL: URL? = nil
    ) {
        self.originalURL = originalURL
        self.title = title
        self.text = text
        self.author = author
        self.titleLink = titleLink
        self.assetURL = assetURL
        self.previewURL = previewURL
    }
}

extension LinkAttachmentPayload: Hashable {}

// MARK: - Encodable

extension LinkAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encode(originalURL, forKey: .ogURL)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(titleLink, forKey: .titleLink)
        try container.encodeIfPresent(assetURL, forKey: .assetURL)
        try container.encodeIfPresent(previewURL, forKey: .thumbURL)
    }
}

// MARK: - Decodable

extension LinkAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)

        let assetURL = try
            container.decodeIfPresent(URL.self, forKey: .imageURL) ??
            container.decodeIfPresent(URL.self, forKey: .image) ??
            container.decodeIfPresent(URL.self, forKey: .assetURL)

        self.init(
            originalURL: try container.decode(URL.self, forKey: .ogURL),
            title: try container
                .decodeIfPresent(String.self, forKey: .title)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            text: try container
                .decodeIfPresent(String.self, forKey: .text)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            author: try container.decodeIfPresent(String.self, forKey: .author),
            titleLink: try container.decodeIfPresent(URL.self, forKey: .titleLink),
            assetURL: assetURL,
            previewURL: try container.decodeIfPresent(URL.self, forKey: .thumbURL) ?? assetURL
        )
    }
}
