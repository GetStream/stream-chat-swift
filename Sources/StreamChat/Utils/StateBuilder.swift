//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A builder for objects requiring @MainActor.
struct StateBuilder<State> {
    private let builder: (@MainActor() -> State)
    
    init(builder: (@escaping @MainActor() -> State)) {
        self.builder = builder
    }
    
    @MainActor func build() -> State {
        builder()
    }
}
