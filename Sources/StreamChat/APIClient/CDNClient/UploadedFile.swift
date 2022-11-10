//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The uploaded file information.
public struct UploadedFile {
    /// The remote url.
    public let remoteURL: URL
    /// The preview/thumbnail  remote url.
    public let remotePreviewURL: URL?

    public init(remoteURL: URL, remotePreviewURL: URL?) {
        self.remoteURL = remoteURL
        self.remotePreviewURL = remotePreviewURL
    }
}
