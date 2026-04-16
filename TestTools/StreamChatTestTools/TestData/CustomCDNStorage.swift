//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@testable import StreamChat

public final class CustomCDNStorage: CDNStorage {
    public func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    ) {}

    public func uploadAttachment(
        localUrl: URL,
        options: AttachmentUploadOptions,
        completion: @escaping @Sendable (Result<UploadedFile, Error>) -> Void
    ) {}

    public func deleteAttachment(
        remoteUrl: URL,
        options: AttachmentDeleteOptions,
        completion: @escaping @Sendable (Error?) -> Void
    ) {}
}
