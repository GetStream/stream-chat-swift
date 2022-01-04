//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `VideoAttachmentPayload` payload type.
///
/// The `ChatMessageVideoAttachment` attachment will be added to the message automatically
/// if the message was sent with attached `AnyAttachmentPayload` created with
/// local URL and `.video` attachment type.
public typealias ChatMessageVideoAttachment = ChatMessageAttachment<VideoAttachmentPayload>

/// Represents a payload for attachments with `.media` type.
public struct VideoAttachmentPayload: AttachmentPayload {
    /// An attachment type all `MediaAttachmentPayload` instances conform to. Is set to `.video`.
    public static let type: AttachmentType = .video

    /// A title, usually the name of the video.
    public var title: String?
    /// A link to the video.
    public var videoURL: URL
    /// The video itself.
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
    
    /// Creates `VideoAttachmentPayload` instance.
    ///
    /// Use this initializer if the attachment is already uploaded and you have the remote URLs.
    public init(title: String?, videoRemoteURL: URL, file: AttachmentFile, extraData: [String: RawJSON]?) {
        self.title = title
        videoURL = videoRemoteURL
        self.file = file
        self.extraData = extraData
    }
}

extension VideoAttachmentPayload: Hashable {}

// MARK: - Encodable

extension VideoAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.title.rawValue] = title.map { .string($0) }
        values[AttachmentCodingKeys.assetURL.rawValue] = .string(videoURL.absoluteString)
        values[AttachmentFile.CodingKeys.size.rawValue] = .number(Double(Int(file.size)))
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
            videoRemoteURL: try container.decode(URL.self, forKey: .assetURL),
            file: try AttachmentFile(from: decoder),
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
