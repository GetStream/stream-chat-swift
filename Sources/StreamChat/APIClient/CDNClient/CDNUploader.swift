//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol for uploading and deleting attachments on a CDN.
///
/// Implement this protocol to use a custom CDN or storage service
/// (such as AWS S3, Firebase Storage, or your own backend) for file uploads.
public protocol CDNUploader: Sendable {
    /// The maximum allowed attachment size in bytes.
    static var maxAttachmentSize: Int64 { get }

    /// Uploads an attachment tied to a message and returns the uploaded file information.
    ///
    /// - Parameters:
    ///   - attachment: The message attachment to upload.
    ///   - progress: A closure that broadcasts upload progress (0.0 to 1.0).
    ///   - completion: A completion handler with the uploaded file result.
    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: (@Sendable (Double) -> Void)?,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    )

    /// Uploads a file from a local URL and returns the uploaded file information.
    ///
    /// - Parameters:
    ///   - localUrl: The local file URL to upload.
    ///   - progress: A closure that broadcasts upload progress (0.0 to 1.0).
    ///   - completion: A completion handler with the uploaded file result.
    func uploadAttachment(
        localUrl: URL,
        progress: (@Sendable (Double) -> Void)?,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    )

    /// Deletes a previously uploaded attachment.
    ///
    /// - Parameters:
    ///   - remoteUrl: The remote URL of the attachment to delete.
    ///   - completion: A completion handler called with an error if the delete fails.
    func deleteAttachment(
        remoteUrl: URL,
        completion: @escaping @Sendable (Error?) -> Void
    )
}

// MARK: - Async/Await Extensions

extension CDNUploader {
    /// Uploads a message attachment and returns the uploaded file information.
    public func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> UploadedFile {
        try await withCheckedThrowingContinuation { continuation in
            uploadAttachment(attachment, progress: progress) { @Sendable result in
                nonisolated(unsafe) let unsafeResult = result
                continuation.resume(with: unsafeResult)
            }
        }
    }

    /// Uploads a file from a local URL and returns the uploaded file information.
    public func uploadAttachment(
        localUrl: URL,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> UploadedFile {
        try await withCheckedThrowingContinuation { continuation in
            uploadAttachment(localUrl: localUrl, progress: progress) { @Sendable result in
                nonisolated(unsafe) let unsafeResult = result
                continuation.resume(with: unsafeResult)
            }
        }
    }

    /// Deletes a previously uploaded attachment.
    public func deleteAttachment(remoteUrl: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            deleteAttachment(remoteUrl: remoteUrl) { @Sendable error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }
}
