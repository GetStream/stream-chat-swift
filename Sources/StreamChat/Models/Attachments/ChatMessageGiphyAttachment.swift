//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing an attachment of type `giphy`.
public struct ChatMessageGiphyAttachment: ChatMessageAttachment, AttachmentEnvelope, Decodable {
    public var type: AttachmentType { .giphy }
    /// A unique identifier of the attachment.
    public var id: AttachmentId?
    /// A  title, usually the search request used to find the gif.
    public let title: String?
    /// A link to `giphy` page of the gif.
    public let titleLink: URL?
    /// A link to gif file.
    public let thumbURL: URL?
    /// Actions when gif is not sent yet. (e.g. `Shuffle`)
    public let actions: [AttachmentAction]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        
        guard (try? container.decode(String.self, forKey: .type)) == AttachmentType.giphy.rawValue else {
            throw DecodingError.dataCorruptedError(
                forKey: AttachmentCodingKeys.type,
                in: container,
                debugDescription: "Error decoding \(Self.self). Type doesn't match"
            )
        }
        
        title = try container.decodeIfPresent(String.self, forKey: .title)
        titleLink = try container.decodeIfPresent(String.self, forKey: .titleLink)?.attachmentFixedURL
        thumbURL = try container.decodeIfPresent(String.self, forKey: .thumbURL)?.attachmentFixedURL
        actions = try container.decodeIfPresent([AttachmentAction].self, forKey: .actions) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(titleLink, forKey: .titleLink)
        try container.encodeIfPresent(thumbURL, forKey: .thumbURL)
    }
}
