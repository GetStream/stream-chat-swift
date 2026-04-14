//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol for uploading and deleting attachments on a CDN.
///
/// Implement this protocol to use a custom CDN or storage service
/// (such as AWS S3, Firebase Storage, or your own backend) for file uploads.
public protocol CDNStorage: Sendable {
    /// Uploads an attachment tied to a message and returns the uploaded file information.
    ///
    /// - Parameters:
    ///   - attachment: The message attachment to upload.
    ///   - options: Options for the upload, such as progress reporting.
    ///   - completion: A completion handler with the uploaded file result.
    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    )

    /// Uploads a file from a local URL and returns the uploaded file information.
    ///
    /// - Parameters:
    ///   - localUrl: The local file URL to upload.
    ///   - options: Options for the upload, such as progress reporting.
    ///   - completion: A completion handler with the uploaded file result.
    func uploadAttachment(
        localUrl: URL,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    )

    /// Deletes a previously uploaded attachment.
    ///
    /// - Parameters:
    ///   - remoteUrl: The remote URL of the attachment to delete.
    ///   - options: Options for the delete operation.
    ///   - completion: A completion handler called with an error if the delete fails.
    func deleteAttachment(
        remoteUrl: URL,
        options: AttachmentDeleteOptions,
        completion: @escaping @Sendable (Error?) -> Void
    )
}

// MARK: - Async/Await Extensions

extension CDNStorage {
    /// Uploads a message attachment and returns the uploaded file information.
    public func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        options: AttachmentUploadOptions = .init()
    ) async throws -> UploadedFile {
        try await withCheckedThrowingContinuation { continuation in
            uploadAttachment(attachment, options: options) { @Sendable result in
                nonisolated(unsafe) let unsafeResult = result
                continuation.resume(with: unsafeResult)
            }
        }
    }

    /// Uploads a file from a local URL and returns the uploaded file information.
    public func uploadAttachment(
        localUrl: URL,
        options: AttachmentUploadOptions = .init()
    ) async throws -> UploadedFile {
        try await withCheckedThrowingContinuation { continuation in
            uploadAttachment(localUrl: localUrl, options: options) { @Sendable result in
                nonisolated(unsafe) let unsafeResult = result
                continuation.resume(with: unsafeResult)
            }
        }
    }

    /// Deletes a previously uploaded attachment.
    public func deleteAttachment(remoteUrl: URL, options: AttachmentDeleteOptions = .init()) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            deleteAttachment(remoteUrl: remoteUrl, options: options) { @Sendable error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }
}

/// Options for uploading an attachment to the CDN.
public struct AttachmentUploadOptions: Sendable {
    /// A closure that broadcasts upload progress (0.0 to 1.0).
    public var progress: (@Sendable (Double) -> Void)?

    public init(progress: (@Sendable (Double) -> Void)? = nil) {
        self.progress = progress
    }
}

/// Options for deleting an attachment from the CDN.
public struct AttachmentDeleteOptions: Sendable {
    public init() {}
}
