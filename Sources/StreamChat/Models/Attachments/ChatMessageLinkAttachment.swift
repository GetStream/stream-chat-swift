//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias ChatMessageLinkAttachment = _ChatMessageAttachment<AttachmentLinkPayload>

public struct AttachmentLinkPayload: AttachmentPayload {
    public static let type: AttachmentType = .linkPreview

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
    public let assetURL: URL
    /// A preview image.
    public let previewURL: URL
}

extension AttachmentLinkPayload: Equatable {}

// MARK: - Encodable

extension AttachmentLinkPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encodeIfPresent(ogURL, forKey: .ogURL)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(titleLink, forKey: .titleLink)
        try container.encode(assetURL, forKey: .assetURL)
        try container.encode(previewURL, forKey: .thumbURL)
    }
}

// MARK: - Decodable

extension AttachmentLinkPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)

        guard
            let assetURL = (
                try container.decodeIfPresent(String.self, forKey: .imageURL) ??
                    container.decodeIfPresent(String.self, forKey: .image) ??
                    container.decodeIfPresent(String.self, forKey: .assetURL)
            )?.attachmentFixedURL
        else {
            throw ClientError.AttachmentDecoding("Link attachment must contain `assetURL`")
        }

        self.init(
            ogURL: try container
                .decodeIfPresent(String.self, forKey: .ogURL)?
                .attachmentFixedURL,
            title: try container
                .decodeIfPresent(String.self, forKey: .title)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            text: try container
                .decodeIfPresent(String.self, forKey: .text)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            author: try container
                .decodeIfPresent(String.self, forKey: .author),
            titleLink: try container
                .decodeIfPresent(String.self, forKey: .titleLink)?
                .attachmentFixedURL,
            assetURL: assetURL,
            previewURL: try container
                .decodeIfPresent(String.self, forKey: .thumbURL)?
                .attachmentFixedURL ?? assetURL
        )
    }
}
