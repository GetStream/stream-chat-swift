//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The options for loading an image into a view.
public struct ImageLoaderOptions {
    // Ideally, the name would be `ImageLoadingOptions`, but this would conflict with Nuke.

    /// The resize information when loading an image. `Nil` if you want the full resolution of the image.
    public var resize: ImageResize?

    /// The placeholder to be used while the image is finishing loading.
    public var placeholder: UIImage?

    public init(resize: ImageResize? = nil, placeholder: UIImage? = nil) {
        self.placeholder = placeholder
        self.resize = resize
    }
}
