//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol an attachment payload type has to conform in order it can be
/// attached to/exposed on the message.
public protocol AttachmentPayload: Codable {
    /// A type of resulting attachment.
    static var type: AttachmentType { get }
}

/// A type-erased type that wraps either a local file URL that has to be uploaded
/// and attached to the message OR a custom payload which the message attachment
/// should contain.
public struct AnyAttachmentPayload {
    /// A type of attachment that will be created when the message is sent.
    public let type: AttachmentType

    /// A payload that will exposed on attachment when the message is sent.
    public let payload: Encodable

    /// A URL referencing to the local file that should be uploaded.
    public let localFileURL: URL?
}

/// Local Metadata related to an attachment.
/// It is used to describe additional information of a local attachment.
public struct AnyAttachmentLocalMetadata {
    /// The original width and height of an image or video attachment in Pixels.
    public var originalResolution: (width: Double, height: Double)?

    /// The duration of a media file
    public var duration: TimeInterval?

    /// The data that can be used to render a waveform visualisation of an audio file.
    public var waveformData: [Float]?

    public init() {}
}

public extension AnyAttachmentPayload {
    /// Creates an instance of `AnyAttachmentPayload` with the given payload.
    ///
    /// - Important: This initializer should only be used for attachments already uploaded or not requiring uploading.
    /// Please use `init(localFileURL:customPayload:)` initializer for custom attachments requiring uploading.
    ///
    /// If attached to the new message the attachment with the given payload will be immediately
    /// available on `ChatMessage` with the `uploadingState == nil` since it doesn't require prior
    /// uploading.
    ///
    /// - Parameter payload: The payload to have the message attachment with.
    init<Payload: AttachmentPayload>(payload: Payload) {
        self.init(
            type: Payload.type,
            payload: payload,
            localFileURL: nil
        )
    }

    /// Creates an instance of `AnyAttachmentPayload` with the given custom payload and local file url.
    /// Use this initialiser if you want to create a custom attachment which will be lazily uploaded after creating a message.
    /// You can track the progress of the attachment upload in your custom `AttachmentViewInjector`.
    ///
    /// - Important: You will need to inject a `ChatClientConfig.uploadedAttachmentPostProcessor` and update the url of your
    ///   custom attachment with the given remote url. You should read the docs on how to properly do this here: https://getstream.io/chat/docs/sdk/ios/uikit/guides/working-with-attachments/#tracking-custom-attachment-upload-progress.
    ///
    /// - Parameters:
    ///   - localFileURL: The local file url in the user's device.
    ///   - customPayload: The custom attachment payload.
    init<Payload: AttachmentPayload>(
        localFileURL: URL,
        customPayload: Payload
    ) {
        self.init(
            type: Payload.type,
            payload: customPayload,
            localFileURL: localFileURL
        )
    }

    /// Creates an instance of `AnyAttachmentPayload` with the URL referencing to a local file.
    ///
    /// The resulting attachment will have `ImageAttachmentPayload` if `attachmentType == .image`.
    /// The resulting attachment will have `VideoAttachmentPayload` if `attachmentType == .video`.
    /// The resulting attachment will have `FileAttachmentPayload` if `attachmentType == .file`.
    /// If the type is different than `.image`/`.video`/`.file` the `ClientError.UnsupportedUploadableAttachmentType` error will be thrown.
    ///
    /// If attached to the new message the attachment with the given payload will be immediately
    /// available on `ChatMessage` with the `uploadingState` reflecting the file uploading progress.
    ///
    /// - Important: Until the message is sent all URLs on exposed attachment will be equal to the given `localFileURL`.
    /// - Important: A given extra data must have dictionary representation.
    ///
    /// - Parameters:
    ///   - localFileURL: The local URL referencing to the file.
    ///   - attachmentType: The type of resulting attachment exposed on the message.
    ///   - localMetadata: The metadata related to the local attachment.
    ///   - extraData: An extra data that should be added to attachment.
    /// - Throws: The error if `localFileURL` is not the file URL or if `extraData` can not be represented as
    /// a dictionary.
    init(
        localFileURL: URL,
        attachmentType: AttachmentType,
        localMetadata: AnyAttachmentLocalMetadata? = nil,
        extraData: Encodable? = nil
    ) throws {
        let file = try AttachmentFile(url: localFileURL)
        let extraData = try extraData
            .flatMap { try JSONEncoder.stream.encode($0.asAnyEncodable) }
            .flatMap { try JSONDecoder.stream.decode([String: RawJSON].self, from: $0) }

        let payload: AttachmentPayload
        switch attachmentType {
        case .image:
            payload = ImageAttachmentPayload(
                title: localFileURL.lastPathComponent,
                imageRemoteURL: localFileURL,
                originalWidth: localMetadata?.originalResolution?.width,
                originalHeight: localMetadata?.originalResolution?.height,
                extraData: extraData
            )
        case .video:
            payload = VideoAttachmentPayload(
                title: localFileURL.lastPathComponent,
                videoRemoteURL: localFileURL,
                thumbnailURL: nil,
                file: file,
                extraData: extraData
            )
        case .audio:
            payload = AudioAttachmentPayload(
                title: localFileURL.lastPathComponent,
                audioRemoteURL: localFileURL,
                file: file,
                extraData: extraData
            )
        case .file:
            payload = FileAttachmentPayload(
                title: localFileURL.lastPathComponent,
                assetRemoteURL: localFileURL,
                file: file,
                extraData: extraData
            )
        case .voiceRecording:
            payload = VoiceRecordingAttachmentPayload(
                title: localFileURL.lastPathComponent,
                voiceRecordingRemoteURL: localFileURL,
                file: file,
                duration: localMetadata?.duration,
                waveformData: localMetadata?.waveformData,
                extraData: extraData
            )
        default:
            throw ClientError.UnsupportedUploadableAttachmentType(attachmentType)
        }

        self.init(
            type: attachmentType,
            payload: payload,
            localFileURL: localFileURL
        )
    }
}

extension ClientError {
    public class UnsupportedUploadableAttachmentType: ClientError {
        init(_ type: AttachmentType) {
            super.init(
                "For uploadable attachments only image/video/audio/file/voiceRecording types are supported."
            )
        }
    }
}

extension AttachmentPayload {
    static func decodeExtraData(from decoder: Decoder) throws -> [String: RawJSON]? {
        guard case let .dictionary(payload) = try RawJSON(from: decoder) else {
            throw ClientError.AttachmentDecoding("Failed to decode extra data.")
        }

        let customPayload = payload.removingValues(
            forKeys:
            AttachmentCodingKeys.allCases.map(\.rawValue) +
                AttachmentFile.CodingKeys.allCases.map(\.rawValue)
        )

        return customPayload.isEmpty ? nil : customPayload
    }
}

extension ChatMessageAttachment<Data> {
    func toAnyAttachmentPayload() -> AnyAttachmentPayload? {
        let types = ChatClient.attachmentTypesRegistry
        guard let payloadType = types[type] else { return nil }
        guard let payload = try? JSONDecoder.default.decode(
            payloadType,
            from: self.payload
        ) else {
            return nil
        }

        // If the attachment is local, we should create the payload as a local file
        if let uploadingState = self.uploadingState, uploadingState.state != .uploaded {
            return AnyAttachmentPayload(type: type, payload: payload, localFileURL: uploadingState.localFileURL)
        }

        return AnyAttachmentPayload(payload: payload)
    }
}

public extension Array where Element == ChatMessageAttachment<Data> {
    func toAnyAttachmentPayload() -> [AnyAttachmentPayload] {
        compactMap { $0.toAnyAttachmentPayload() }
    }
}
