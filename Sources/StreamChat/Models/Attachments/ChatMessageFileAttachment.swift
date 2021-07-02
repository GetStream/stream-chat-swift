//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `FileAttachmentPayload` payload type.
///
/// The `ChatMessageFileAttachment` attachment will be added to the message automatically
/// if the message was sent with attached `AnyAttachmentPayload` created with
/// local URL and `.file` attachment type.
public typealias ChatMessageFileAttachment = _ChatMessageAttachment<FileAttachmentPayload>

/// Represents a payload for attachments with `.file` type.
public struct FileAttachmentPayload: AttachmentPayload {
    /// An attachment type all `FileAttachmentPayload` instances conform to. Is set to `.file`.
    public static let type: AttachmentType = .file

    /// A title, usually the name of the file.
    public let title: String?
    /// A link to the file.
    public internal(set) var assetURL: URL
    /// The file itself.
    public let file: AttachmentFile
}

extension FileAttachmentPayload: Equatable {}

// MARK: - Encodable

extension FileAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(assetURL, forKey: .assetURL)
        try file.encode(to: encoder)
    }
}

// MARK: - Decodable

extension FileAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        
        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title),
            assetURL: try container.decode(URL.self, forKey: .assetURL),
            file: try AttachmentFile(from: decoder)
        )
    }
}
