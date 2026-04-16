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

    public init(resize: ImageResize? = nil) {
        self.resize = resize
    }

    @available(*, deprecated, message: "CDNRequester is now a dependency of StreamMediaLoader. Pass it when creating the loader instead.")
    public init(resize: ImageResize? = nil, cdnRequester: CDNRequester) {
        self.resize = resize
    }
}
