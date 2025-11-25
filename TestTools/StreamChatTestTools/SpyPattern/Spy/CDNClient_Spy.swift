//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

final class CDNClient_Spy: CDNClient, Spy {
    let spyState = SpyState()

    static var maxAttachmentSize: Int64 { .max }
    var uploadAttachmentProgress: Double?
    var uploadAttachmentResult: Result<URL, Error>?
    
    var deleteAttachmentRemoteUrl: URL?
    var deleteAttachmentType: AttachmentType?
    var deleteAttachmentResult: Error?

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        record()
        if let uploadAttachmentProgress = uploadAttachmentProgress {
            progress?(uploadAttachmentProgress)
        }

        if let uploadAttachmentResult = uploadAttachmentResult {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(uploadAttachmentResult)
            }
        }
    }
    
    func uploadStandaloneAttachment<Payload>(
        _ attachment: StreamAttachment<Payload>,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedFile, any Error>) -> Void
    ) {
        record()
        if let uploadAttachmentProgress = uploadAttachmentProgress {
            progress?(uploadAttachmentProgress)
        }

        if let uploadAttachmentResult = uploadAttachmentResult {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(uploadAttachmentResult.map { UploadedFile(fileURL: $0) })
            }
        }
    }
    
    func deleteAttachment(
        remoteUrl: URL,
        attachmentType: AttachmentType,
        completion: @escaping (Error?) -> Void
    ) {
        record()
        deleteAttachmentRemoteUrl = remoteUrl
        deleteAttachmentType = attachmentType
        if let result = deleteAttachmentResult {
            completion(result)
        }
    }
}
