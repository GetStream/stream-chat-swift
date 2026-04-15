//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI

extension Components {
    static var mock: Self {
        var components = Self()
        components.mediaLoader = ImageLoader_Mock()
        return components
    }

    var mockMediaLoader: ImageLoader_Mock { mediaLoader as! ImageLoader_Mock }
}
