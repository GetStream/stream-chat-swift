//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `AudioAttachmentPayload` payload type.
///
/// The `ChatMessageAudioAttachment` attachment will be added to the message automatically
/// if the message was sent with attached `AnyAttachmentPayload` created with
/// local URL and `.audio` attachment type.
public typealias ChatMessageAudioAttachment = ChatMessageAttachment<AudioAttachmentPayload>

/// Represents a payload for attachments with `.media` type.
public struct AudioAttachmentPayload: AttachmentPayload {
    /// An attachment type all `MediaAttachmentPayload` instances conform to. Is set to `.audio`.
    public static let type: AttachmentType = .audio
    
    /// A title, usually the name of the audio.
    public var title: String?
    /// A link to the audio.
    public var audioURL: URL
    /// The audio itself.
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

extension AudioAttachmentPayload: Equatable {}

// MARK: - Encodable

extension AudioAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.title.rawValue] = title.map { .string($0) }
        values[AttachmentCodingKeys.assetURL.rawValue] = .string(audioURL.absoluteString)
        values[AttachmentFile.CodingKeys.size.rawValue] = .number(Double(file.size))
        values[AttachmentFile.CodingKeys.mimeType.rawValue] = file.mimeType.map { .string($0) }
        try values.encode(to: encoder)
    }
}

// MARK: - Decodable

extension AudioAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        
        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title),
            audioURL: try container.decode(URL.self, forKey: .assetURL),
            file: try AttachmentFile(from: decoder),
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
