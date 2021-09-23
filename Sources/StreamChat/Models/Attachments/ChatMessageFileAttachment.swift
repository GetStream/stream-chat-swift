//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `FileAttachmentPayload` payload type.
///
/// The `ChatMessageFileAttachment` attachment will be added to the message automatically
/// if the message was sent with attached `AnyAttachmentPayload` created with
/// local URL and `.file` attachment type.
public typealias ChatMessageFileAttachment = ChatMessageAttachment<FileAttachmentPayload>

/// Represents a payload for attachments with `.file` type.
public struct FileAttachmentPayload: AttachmentPayload {
    /// An attachment type all `FileAttachmentPayload` instances conform to. Is set to `.file`.
    public static let type: AttachmentType = .file

    /// A title, usually the name of the file.
    public var title: String?
    /// A link to the file.
    public var assetURL: URL
    /// The file itself.
    public var file: AttachmentFile
    /// An extra data.
    public var extraData: [String: RawJSON]?
    
    /// Decodes extra data as an instance of the given type.
    /// - Parameter ofType: The type an extra data should be decoded as.
    /// - Returns: Extra data of the given type or `nil` if decoding fails.
    public func extraData<T: Decodable>(ofType: T.Type = T.self) -> T? {
        extraData
            .flatMap { try? JSONEncoder.stream.encode($0) }
            .flatMap { try? JSONDecoder.stream.decode(T.self, from: $0) }
    }
}

extension FileAttachmentPayload: Hashable {}

// MARK: - Encodable

extension FileAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.title.rawValue] = title.map { .string($0) }
        values[AttachmentCodingKeys.assetURL.rawValue] = .string(assetURL.absoluteString)
        values[AttachmentFile.CodingKeys.size.rawValue] = .number(Double(Int(file.size)))
        values[AttachmentFile.CodingKeys.mimeType.rawValue] = file.mimeType.map { .string($0) }
        try values.encode(to: encoder)
    }
}

// MARK: - Decodable

extension FileAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        
        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title),
            assetURL: try container.decode(URL.self, forKey: .assetURL),
            file: try AttachmentFile(from: decoder),
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
