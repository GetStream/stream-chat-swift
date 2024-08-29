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
    ///
    /// - Returns: The file information if it is part of the attachment payload,
    /// otherwise it is extracted from the downloaded file.
    public let file: AttachmentFile?
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

/// The attachment payload which can be downloaded.
public typealias DownloadableAttachmentPayload = AttachmentPayloadDownloading & AttachmentPayload

/// A capability of downloading attachment payload data to the local storage.
public protocol AttachmentPayloadDownloading {
    /// The file name used for storing the attachment file locally.
    ///
    /// Example: `myfile.txt`
    ///
    /// - Note: Does not need to be unique.
    var localStorageFileName: String { get }
    
    /// The remote URL of the attachment what can be downloaded and stored locally.
    ///
    /// For example, an image for image attachments.
    var remoteURL: URL { get }
}

extension AttachmentFile {
    func defaultLocalStorageFileName(for attachmentType: AttachmentType) -> String {
        "\(attachmentType.rawValue.localizedCapitalized).\(type.rawValue)" // image.jpeg
    }
}

extension URL {
    /// The directory URL for attachment downloads.
    static var streamAttachmentDownloadsDirectory: URL {
        (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("StreamAttachmentDownloads", isDirectory: true)
    }
    
    static func streamAttachmentLocalStorageURL(forRelativePath path: String) -> URL {
        URL(fileURLWithPath: path, isDirectory: false, relativeTo: .streamAttachmentDownloadsDirectory).standardizedFileURL
    }
}

extension ChatMessageAttachment where Payload: AttachmentPayloadDownloading {
    /// A local and unique file path for the attachment.
    var relativeStoragePath: String {
        "\(id.messageId)-\(id.index)/\(payload.localStorageFileName)"
    }
}
