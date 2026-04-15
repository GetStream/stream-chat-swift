//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat

extension VideoLoader {
    /// Returns a video asset for the given URL.
    ///
    /// The default implementation creates an `AVURLAsset` directly from the URL.
    /// Override in a custom `VideoLoader` to apply CDN requester-signed URLs.
    public func videoAsset(at url: URL, options: VideoLoadOptions) -> AVURLAsset {
        AVURLAsset(url: url)
    }
}
