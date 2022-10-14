//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// The options for loading an image into a view.
public struct ImageLoaderOptions {
    // Ideally, the name would be `ImageLoadingOptions`, but this would conflict with Nuke.

    /// The placeholder to be used while the image is finishing loading.
    public var placeholder: UIImage?
    /// The resize information when loading an image. `Nil` if you want the full resolution of the image.
    public var resize: ImageResize?

    public init(placeholder: UIImage? = nil, resize: ImageResize? = nil) {
        self.placeholder = placeholder
        self.resize = resize
    }
}
