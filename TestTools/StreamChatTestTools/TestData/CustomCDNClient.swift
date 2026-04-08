//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@testable import StreamChat

public final class CustomCDNUploader: CDNUploader {
    public static var maxAttachmentSize: Int64 { 10 * 1000 * 1000 }

    public func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: (@Sendable (Double) -> Void)?,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    ) {}

    public func uploadAttachment(
        localUrl: URL,
        progress: (@Sendable (Double) -> Void)?,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    ) {}

    public func deleteAttachment(
        remoteUrl: URL,
        completion: @escaping @Sendable (Error?) -> Void
    ) {}
}
