//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import StreamChatCommonUI

extension VideoLoader {
    /// Returns a video asset for the given URL.
    ///
    /// Override in a custom `VideoLoader` to apply CDN-signed URLs.
    public func videoAsset(at url: URL) -> AVURLAsset {
        AVURLAsset(url: url)
    }
}
