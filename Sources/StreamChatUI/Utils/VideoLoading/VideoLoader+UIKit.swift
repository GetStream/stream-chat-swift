//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import AVKit

extension VideoLoader {
    /// Returns a video asset for the given URL.
    ///
    /// Override in a custom `VideoLoader` to apply CDN requester-signed URLs.
    public func videoAsset(at url: URL) -> AVURLAsset {
        AVURLAsset(url: url)
    }
}
