//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI

extension Components {
    static var mock: Self {
        var components = Self()
        components.imageLoader = ImageLoader_Mock()
        components.videoLoader = VideoLoader_Mock()
        return components
    }
    
    var mockImageLoader: ImageLoader_Mock { imageLoader as! ImageLoader_Mock }
    var mockVideoLoader: VideoLoader_Mock { videoLoader as! VideoLoader_Mock }
}
