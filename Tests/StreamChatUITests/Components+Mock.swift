//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI

extension Components {
    static var mock: Self {
        var components = Self()
        components.imageLoader = MockImageLoader()
        components.videoLoader = MockVideoLoader()
        return components
    }
    
    var mockImageLoader: MockImageLoader { imageLoader as! MockImageLoader }
    var mockVideoLoader: MockVideoLoader { videoLoader as! MockVideoLoader }
}
