//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a chat message attachment.
/// `ChatMessageAttachment<Payload>` is an immutable snapshot of message attachment at the given time.
@dynamicMemberLookup
public struct ChatMessageAttachment<Payload> {
    /// The attachment identifier.
    public let id: AttachmentId

    /// The attachment type.
    public let type: AttachmentType

    /// The attachment payload.
    public var payload: Payload

    /// The downloading state of the attachment.
    ///
    /// Reflects the downloading progress for attachments.
    public let downloadingState: AttachmentDownloadingState?
    
    /// The uploading state of the attachment.
    ///
    /// Reflects uploading progress for local attachments that require file uploading.
    /// Is `nil` for local attachments that don't need to be uploaded.
    ///
    /// Becomes `nil` when the message with the current attachment is sent.
    public let uploadingState: AttachmentUploadingState?

    public init(
        id: AttachmentId,
        type: AttachmentType,
        payload: Payload,
        downloadingState: AttachmentDownloadingState?,
        uploadingState: AttachmentUploadingState?
    ) {
        self.id = id
        self.type = type
        self.payload = payload
        self.downloadingState = downloadingState
        self.uploadingState = uploadingState
    }
}

public extension ChatMessageAttachment {
    subscript<T>(dynamicMember keyPath: KeyPath<Payload, T>) -> T {
        payload[keyPath: keyPath]
    }
}

extension ChatMessageAttachment: Equatable where Payload: Equatable {}
extension ChatMessageAttachment: Hashable where Payload: Hashable {}

/// A type represeting the downloading state for attachments.
public struct AttachmentDownloadingState: Hashable {
    /// The local file URL of the downloaded attachment.
    ///
    /// - Note: The local file URL is available when the state is `.downloaded`.
    public let localFileURL: URL?
    
    /// The local download state of the attachment.
    public let state: LocalAttachmentDownloadState
    
    /// The information about file size/mimeType.
    public let file: AttachmentFile
}

/// A type representing the uploading state for attachments that require prior uploading.
public struct AttachmentUploadingState: Hashable {
    /// The local file URL that is being uploaded.
    public let localFileURL: URL

    /// The uploading state.
    public let state: LocalAttachmentState

    /// The information about file size/mimeType.
    public let file: AttachmentFile
}

// MARK: - Type erasure/recovery

public typealias AnyChatMessageAttachment = ChatMessageAttachment<Data>

public extension AnyChatMessageAttachment {
    /// Converts type-erased attachment to the attachment with the concrete payload.
    ///
    /// Attachment with the requested payload type will be returned if the type-erased payload
    /// has a `Payload` instance under the hood OR if it’s a `Data` that can be decoded as a `Payload`.
    ///
    /// - Parameter payloadType: The payload type the current type-erased attachment payload should be treated as.
    /// - Returns: The attachment with the requested payload type or `nil`.
    func attachment<PayloadData: AttachmentPayload>(
        payloadType: PayloadData.Type
    ) -> ChatMessageAttachment<PayloadData>? {
        guard
            PayloadData.type == type || type == .unknown,
            let concretePayload = try? JSONDecoder.stream.decode(PayloadData.self, from: payload)
        else { return nil }

        return .init(
            id: id,
            type: type,
            payload: concretePayload,
            downloadingState: downloadingState,
            uploadingState: uploadingState
        )
    }
}

// swiftlint:disable force_try
public extension ChatMessageAttachment where Payload: AttachmentPayload {
    /// Returns an attachment matching `self` but payload casted to `Any`.
    var asAnyAttachment: AnyChatMessageAttachment {
        AnyChatMessageAttachment(
            id: id,
            type: type,
            payload: try! JSONEncoder.stream.encode(payload),
            downloadingState: downloadingState,
            uploadingState: uploadingState
        )
    }
}

// swiftlint:enable force_try

public extension ChatMessageAttachment where Payload: AttachmentPayload {
    func asAttachment<NewPayload: AttachmentPayload>(
        payloadType: NewPayload.Type
    ) -> ChatMessageAttachment<NewPayload>? {
        guard
            let payloadData = try? JSONEncoder.stream.encode(payload),
            let concretePayload = try? JSONDecoder.stream.decode(NewPayload.self, from: payloadData)
        else {
            return nil
        }

        return .init(
            id: id,
            type: .file,
            payload: concretePayload,
            downloadingState: downloadingState,
            uploadingState: uploadingState
        )
    }
}

// MARK: - Local Downloads

extension URL {
    /// The directory URL for attachment downloads.
    static var streamAttachmentDownloadsDirectory: URL {
        (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("AttachmentDownloads", isDirectory: true)
    }
}

extension AnyChatMessageAttachment {
    static func localStorageURL(forRelativePath path: String) -> URL {
        URL(fileURLWithPath: path, isDirectory: false, relativeTo: .streamAttachmentDownloadsDirectory).standardizedFileURL
    }
    
    private func assetInfo() throws -> (title: String?, url: URL) {
        if let attachment = attachment(payloadType: FileAttachmentPayload.self) {
            return (attachment.title, attachment.assetURL)
        }
        if let attachment = attachment(payloadType: ImageAttachmentPayload.self) {
            return (attachment.title, attachment.imageURL)
        }
        if let attachment = attachment(payloadType: VideoAttachmentPayload.self) {
            return (attachment.title, attachment.videoURL)
        }
        if let attachment = attachment(payloadType: AudioAttachmentPayload.self) {
            return (attachment.title, attachment.audioURL)
        }
        if let attachment = attachment(payloadType: VoiceRecordingAttachmentPayload.self) {
            return (attachment.title, attachment.voiceRecordingURL)
        }
        if let attachment = attachment(payloadType: GiphyAttachmentPayload.self) {
            return (attachment.title, attachment.previewURL)
        }
        throw ClientError.AttachmentDownloading(id: id, reason: "Download is unavailable")
    }
    
    var downloadURL: URL {
        get throws {
            try assetInfo().url
        }
    }
    
    var relativeStoragePath: String {
        let fileName: String = {
            guard let assetInfo = try? assetInfo() else { return "unknown" }
            return assetInfo.title ?? assetInfo.url.lastPathComponent
        }()
        return "\(id.messageId)-\(id.index)-\(fileName)"
    }
}
