//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `VideoAttachmentPayload` payload type.
///
/// The `ChatMessageVideoAttachment` attachment will be added to the message automatically
/// if the message was sent with attached `AnyAttachmentPayload` created with
/// local URL and `.video` attachment type.
public typealias ChatMessageVideoAttachment = _ChatMessageAttachment<VideoAttachmentPayload>

/// Represents a payload for attachments with `.media` type.
public struct VideoAttachmentPayload: AttachmentPayload {
    /// An attachment type all `MediaAttachmentPayload` instances conform to. Is set to `.video`.
    public static let type: AttachmentType = .video

    /// A title, usually the name of the video.
    public let title: String?
    /// A link to the video.
    public internal(set) var videoURL: URL
    /// The video itself.
    public let file: AttachmentFile
    /// An extra data.
    let extraData: [String: RawJSON]?
    
    /// Decodes extra data as an instance of the given type.
    /// - Parameter ofType: The type an extra data should be decoded as.
    /// - Returns: Extra data of the given type or `nil` if decoding fails.
    public func extraData<T: Decodable>(ofType: T.Type = T.self) -> T? {
        extraData
            .flatMap { try? JSONEncoder.stream.encode($0) }
            .flatMap { try? JSONDecoder.stream.decode(T.self, from: $0) }
    }
}

extension VideoAttachmentPayload: Equatable {}

// MARK: - Encodable

extension VideoAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.title.rawValue] = title.map { .string($0) }
        values[AttachmentCodingKeys.assetURL.rawValue] = .string(videoURL.absoluteString)
        values[AttachmentFile.CodingKeys.size.rawValue] = .integer(Int(file.size))
        values[AttachmentFile.CodingKeys.mimeType.rawValue] = file.mimeType.map { .string($0) }
        try values.encode(to: encoder)
    }
}

// MARK: - Decodable

extension VideoAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        
        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title),
            videoURL: try container.decode(URL.self, forKey: .assetURL),
            file: try AttachmentFile(from: decoder),
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
