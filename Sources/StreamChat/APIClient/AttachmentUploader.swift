//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The attachment which was successfully uploaded.
public struct UploadedAttachment {
    /// The attachment which contains the payload details of the attachment.
    public var attachment: AnyChatMessageAttachment

    /// The uploaded file remote information.
    public var file: UploadedFile

    public init(
        originalAttachment: AnyChatMessageAttachment,
        uploadedFile: UploadedFile
    ) {
        file = uploadedFile

        var updatedAttachment = originalAttachment
        let updatedPayload: AnyEncodable

        if let imageAttachment = originalAttachment.attachment(payloadType: ImageAttachmentPayload.self) {
            var payload = imageAttachment.payload
            payload.imageURL = file.remoteURL
            if let previewURL = file.remotePreviewURL {
                payload.imagePreviewURL = previewURL
            }
            updatedPayload = payload.asAnyEncodable
        } else if let videoAttachment = originalAttachment.attachment(payloadType: VideoAttachmentPayload.self) {
            var payload = videoAttachment.payload
            payload.videoURL = file.remoteURL
            updatedPayload = payload.asAnyEncodable
        } else if let audioAttachment = originalAttachment.attachment(payloadType: AudioAttachmentPayload.self) {
            var payload = audioAttachment.payload
            payload.audioURL = file.remoteURL
            updatedPayload = payload.asAnyEncodable
        } else if let fileAttachment = originalAttachment.attachment(payloadType: FileAttachmentPayload.self) {
            var payload = fileAttachment.payload
            payload.assetURL = file.remoteURL
            updatedPayload = payload.asAnyEncodable
        } else {
            updatedPayload = originalAttachment.payload.asAnyEncodable
        }

        do {
            updatedAttachment.payload = try JSONEncoder.stream.encode(updatedPayload)
            attachment = updatedAttachment
        } catch {
            attachment = originalAttachment
        }
    }
}

public protocol AttachmentUploader {
    func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
    )
}

public class StreamAttachmentUploader: AttachmentUploader {
    let cdnClient: CDNClient

    init(cdnClient: CDNClient) {
        self.cdnClient = cdnClient
    }

    public func upload(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
    ) {
        cdnClient.upload(attachment, progress: progress) { result in
            completion(result.map { uploadedFile in
                UploadedAttachment(
                    originalAttachment: attachment,
                    uploadedFile: uploadedFile
                )
            })
        }
    }
}
