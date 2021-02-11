//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing an attachment of type `file`.
public struct ChatMessageFileAttachment: ChatMessageAttachment, AttachmentEnvelope, Decodable {
    public var type: AttachmentType { .file }
    /// A unique identifier of the attachment.
    public var id: AttachmentId?
    
    /// When a new attachment is created, this value contains the URL of the source from which the attachment
    /// data are uploaded to the server. For already sent attachments this value is usually `nil`. This value is
    /// device-specific and is not synced with other devices.
    public var localURL: URL?
    /// A local attachment state
    public var localState: LocalAttachmentState?
    
    /// A title, usually the file name.
    public let title: String?
    /// A link to the file.
    public var assetURL: URL?
    /// A file info.
    public let file: AttachmentFile?
    
    init(
        title: String,
        file: AttachmentFile
    ) {
        self.title = title
        self.file = file
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        
        guard (try? container.decode(String.self, forKey: .type)) == AttachmentType.file.rawValue else {
            throw DecodingError.dataCorruptedError(
                forKey: AttachmentCodingKeys.type,
                in: container,
                debugDescription: "Error decoding \(Self.self). Type doesn't match"
            )
        }
        
        title = try container.decodeIfPresent(String.self, forKey: .title)
        assetURL = try container.decodeIfPresent(String.self, forKey: .assetURL)?.attachmentFixedURL
        file = try AttachmentFile(from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(assetURL, forKey: .assetURL)
        try container.encodeIfPresent(title, forKey: .title)
        try file?.encode(to: encoder)
    }
}
