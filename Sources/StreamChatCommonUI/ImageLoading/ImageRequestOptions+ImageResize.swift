//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat

extension ImageRequestOptions {
    /// Builds CDN image request options from UI resize parameters.
    public init(imageResize: ImageResize?) {
        self.init(
            resize: imageResize.map {
                CDNImageResize(
                    width: $0.width,
                    height: $0.height,
                    resizeMode: $0.mode.value,
                    crop: $0.mode.cropValue
                )
            }
        )
    }
}
