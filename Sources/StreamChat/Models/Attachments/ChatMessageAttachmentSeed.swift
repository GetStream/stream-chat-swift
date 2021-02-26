//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type designed to combine all the information required to create new attachment that needs to be uploaded before sending.
public struct ChatMessageAttachmentSeed: AttachmentEnvelope, Hashable {
    /// A local url the data for uploading will be taken from.
    /// When an attachment in uploaded and a message is sent the `localURL` of resulting
    /// `ChatMessageAttachment` will be equal to this value.
    public let localURL: URL
    /// When the attachment is created the filename will be available under `ChatMessageAttachment.title` field.
    /// A `localURL.lastPathComponent` might be a good option.
    public let fileName: String
    /// An attachment type (see `AttachmentType`).
    public let type: AttachmentType
    
    var localState: LocalAttachmentState?

    var file: AttachmentFile {
        let fileType = AttachmentFileType(ext: localURL.pathExtension)
        return .init(
            type: fileType,
            size: localURL.fileSize,
            mimeType: fileType.mimeType
        )
    }

    /// Creates a new `ChatMessageAttachmentSeed` instance
    /// - Parameters:
    ///   - localURL: The local file URL the attachment will be uploaded from.
    ///   - fileName: The filename. Once attachment is uploaded this value will
    ///   be available under `ChatMessageAttachment.title` field. If `nil` is provided the `localURL.lastPathComponent`
    ///   will be used.
    ///   - type: The attachment type. Attachment rendering will be chosen based on it type.
    public init(
        localURL: URL,
        fileName: String? = nil,
        type: AttachmentType
    ) {
        self.localURL = localURL
        self.fileName = fileName ?? localURL.lastPathComponent
        self.type = type
    }
    
    init(
        localURL: URL,
        fileName: String?,
        type: AttachmentType,
        localState: LocalAttachmentState
    ) {
        self.localURL = localURL
        self.fileName = fileName ?? localURL.lastPathComponent
        self.type = type
        self.localState = localState
    }
    
    // Dummy encodable conformance to satisfy `AttachmentEnvelope` protocol.
    public func encode(to encoder: Encoder) throws {}
}

private extension URL {
    var fileSize: Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.size] as? Int64 ?? 0
    }
}
