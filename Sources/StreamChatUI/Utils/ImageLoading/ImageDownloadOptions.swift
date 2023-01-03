//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// The options for downloading an image.
public struct ImageDownloadOptions {
    /// The resize information when loading an image. `Nil` if you want the full resolution of the image.
    public var resize: ImageResize?

    public init(resize: ImageResize? = nil) {
        self.resize = resize
    }
}
