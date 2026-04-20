//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatCommonUI

/// The options for downloading an image.
public struct ImageDownloadOptions: Sendable {
    /// The resize information when loading an image. `Nil` if you want the full resolution of the image.
    public var resize: ImageResize?

    /// The CDN requester for URL transformation (signing, headers, resizing).
    public var cdnRequester: CDNRequester

    public init(resize: ImageResize? = nil, cdnRequester: CDNRequester) {
        self.resize = resize
        self.cdnRequester = cdnRequester
    }
}
