//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI

extension Components {
    static var mock: Self {
        var components = Self()
        components.imageLoader = MockImageLoader()
        return components
    }
}
