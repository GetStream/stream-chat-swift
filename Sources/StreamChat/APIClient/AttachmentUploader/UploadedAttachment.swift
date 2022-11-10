//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The attachment which was successfully uploaded.
public struct UploadedAttachment {
    /// The attachment which contains the payload details of the attachment.
    public var attachment: AnyChatMessageAttachment

    /// The original file remote url.
    public let remoteURL: URL

    /// The preview file remote url.
    public let remotePreviewURL: URL?

    public init(
        attachment: AnyChatMessageAttachment,
        remoteURL: URL,
        remotePreviewURL: URL? = nil
    ) {
        self.attachment = attachment
        self.remoteURL = remoteURL
        self.remotePreviewURL = remotePreviewURL
    }
}
