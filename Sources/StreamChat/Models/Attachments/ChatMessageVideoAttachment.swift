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
}

extension VideoAttachmentPayload: Equatable {}

// MARK: - Encodable

extension VideoAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(videoURL, forKey: .assetURL)
        try file.encode(to: encoder)
    }
}

// MARK: - Decodable

extension VideoAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)

        guard
            let assetURL = try container
            .decodeIfPresent(String.self, forKey: .assetURL)?
            .attachmentFixedURL
        else {
            throw ClientError.AttachmentDecoding("Video attachment must contain `assetURL`")
        }

        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title),
            videoURL: assetURL,
            file: try AttachmentFile(from: decoder)
        )
    }
}
