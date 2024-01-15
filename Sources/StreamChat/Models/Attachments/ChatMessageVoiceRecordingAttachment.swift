//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `VoiceRecordingAttachmentPayload` payload type.
///
/// The `ChatMessageVoiceRecordingAttachment` attachment will be added to the message
/// automatically if the message was sent with attached `AnyAttachmentPayload` created with
/// local URL and `.voiceRecording` attachment type.
public typealias ChatMessageVoiceRecordingAttachment = ChatMessageAttachment<VoiceRecordingAttachmentPayload>

/// Represents a payload for attachments with `.voiceRecording` type.
public struct VoiceRecordingAttachmentPayload: AttachmentPayload {
    /// An attachment type all `VoiceRecordingAttachmentPayload` instances conform to.
    /// Is set to `.voiceRecording`.
    public static let type: AttachmentType = .voiceRecording

    /// A title, usually the name of the voiceRecording.
    public var title: String?
    /// A link to the voiceRecording.
    public var voiceRecordingURL: URL
    /// The voiceRecording itself.
    public var file: AttachmentFile
    /// The duration of the attached Audio file
    public var duration: TimeInterval?
    /// The waveformData that can be used to create waveform visualisation of the attached Audio file
    public var waveformData: [Float]?

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

    /// Creates `VoiceRecordingAttachmentPayload` instance.
    ///
    /// Use this initializer if the attachment is already uploaded and you have the remote URLs.
    public init(
        title: String?,
        voiceRecordingRemoteURL: URL,
        file: AttachmentFile,
        duration: TimeInterval?,
        waveformData: [Float]?,
        extraData: [String: RawJSON]?
    ) {
        self.title = title
        voiceRecordingURL = voiceRecordingRemoteURL
        self.file = file
        self.duration = duration
        self.waveformData = waveformData
        self.extraData = extraData
    }
}

extension VoiceRecordingAttachmentPayload: Hashable {}

extension VoiceRecordingAttachmentPayload {
    public enum CodingKeys: String, CodingKey {
        case duration
        case waveformData = "waveform_data"
    }
}

// MARK: - Encodable

extension VoiceRecordingAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.title.rawValue] = title.map { .string($0) }
        values[AttachmentCodingKeys.assetURL.rawValue] = .string(voiceRecordingURL.absoluteString)
        values[AttachmentFile.CodingKeys.size.rawValue] = .number(Double(file.size))
        values[AttachmentFile.CodingKeys.mimeType.rawValue] = file.mimeType.map { .string($0) }
        values[VoiceRecordingAttachmentPayload.CodingKeys.duration.rawValue] = duration.map { .number(Double($0)) }
        values[VoiceRecordingAttachmentPayload.CodingKeys.waveformData.rawValue] = waveformData.map { waveformData in .array(waveformData.map { .number(Double($0)) }) }
        try values.encode(to: encoder)
    }
}

// MARK: - Decodable

extension VoiceRecordingAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        let voiceRecordingContainer = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title),
            voiceRecordingRemoteURL: try container.decode(URL.self, forKey: .assetURL),
            file: try AttachmentFile(from: decoder),
            duration: try voiceRecordingContainer.decodeIfPresent(TimeInterval.self, forKey: .duration),
            waveformData: try voiceRecordingContainer.decodeIfPresent([Float].self, forKey: .waveformData),
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
