//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    public let payload: Encodable?

    /// A URL referencing to the local file that should be uploaded.
    public let localFileURL: URL?
}

public extension AnyAttachmentPayload {
    /// Creates an instance of `AnyAttachmentPayload` with the given payload.
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
    ///
    /// - Parameters:
    ///   - localFileURL: The local URL referencing to the file.
    ///   - attachmentType: The type of resulting attachment exposed on the message.
    /// - Throws: The error if `localFileURL` is not the file URL.
    init(localFileURL: URL, attachmentType: AttachmentType) throws {
        let file = try AttachmentFile(url: localFileURL)

        let payload: AttachmentPayload
        switch attachmentType {
        case .image:
            payload = ImageAttachmentPayload(
                title: localFileURL.lastPathComponent,
                imageURL: localFileURL,
                imagePreviewURL: localFileURL
            )
        case .video:
            payload = VideoAttachmentPayload(
                title: localFileURL.lastPathComponent,
                videoURL: localFileURL,
                file: file
            )
        case .file:
            payload = FileAttachmentPayload(
                title: localFileURL.lastPathComponent,
                assetURL: localFileURL,
                file: file
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
                "For uploadable attachments only .image/.file/.video types are supported."
            )
        }
    }
}
