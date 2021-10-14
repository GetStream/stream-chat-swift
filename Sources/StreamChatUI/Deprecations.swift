//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

/// - NOTE: Deprecations of the next major release.

@available(*, deprecated, renamed: "VideoLoading")
public typealias VideoPreviewLoader = VideoLoading

public extension Components {
    @available(*, deprecated, renamed: "videoLoader")
    var videoPreviewLoader: VideoLoading {
        get { videoLoader }
        set { videoLoader = newValue }
    }
}
