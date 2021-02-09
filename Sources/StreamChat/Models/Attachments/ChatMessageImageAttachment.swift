//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing an attachment of type `image`.
public struct ChatMessageImageAttachment: ChatMessageAttachment, AttachmentEnvelope, Decodable {
    public var type: AttachmentType { .image }
    /// A unique identifier of the attachment.
    public var id: AttachmentId?
    
    /// When a new attachment is created, this value contains the URL of the source from which the attachment
    /// data are uploaded to the server. For already sent attachments this value is usually `nil`. This value is
    /// device-specific and is not synced with other devices.
    public var localURL: URL?
    /// A local attachment state
    public var localState: LocalAttachmentState?
    
    /// A title, usually the name of the image.
    public let title: String?
    /// A link to the image.
    public var imageURL: URL?
    /// A link to the image preview.
    public let imagePreviewURL: URL?
    
    init(title: String) {
        self.title = title
        imagePreviewURL = nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        
        guard (try? container.decode(String.self, forKey: .type)) == AttachmentType.image.rawValue else {
            throw DecodingError.dataCorruptedError(
                forKey: AttachmentCodingKeys.type,
                in: container,
                debugDescription: "Error decoding \(Self.self). Type doesn't match"
            )
        }
        
        title = (
            try container.decodeIfPresent(String.self, forKey: .title)
                ?? container.decodeIfPresent(String.self, forKey: .fallback)
                ?? container.decodeIfPresent(String.self, forKey: .name)
                ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        
        imageURL = (
            try container.decodeIfPresent(String.self, forKey: .image)
                ?? container.decodeIfPresent(String.self, forKey: .imageURL)
                ?? container.decodeIfPresent(String.self, forKey: .assetURL)
                ?? container.decodeIfPresent(String.self, forKey: .thumbURL)
        )?.attachmentFixedURL
        
        imagePreviewURL = try container.decodeIfPresent(String.self, forKey: .thumbURL)?.attachmentFixedURL
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .fallback)
        try container.encode(imageURL, forKey: .imageURL)
    }
}
