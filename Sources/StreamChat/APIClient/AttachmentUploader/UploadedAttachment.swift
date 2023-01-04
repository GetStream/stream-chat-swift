//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// The attachment which was successfully uploaded.
public struct UploadedAttachment {
    /// The attachment which contains the payload details of the attachment.
    public var attachment: AnyChatMessageAttachment

    /// The original file remote url.
    public let remoteURL: URL

    public init(
        attachment: AnyChatMessageAttachment,
        remoteURL: URL
    ) {
        self.attachment = attachment
        self.remoteURL = remoteURL
    }
}
