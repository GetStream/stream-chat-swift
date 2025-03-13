//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

struct StateBackgroundBuilder<State> {
    private let builder: (() -> State)
    
    init(builder: (@escaping () -> State)) {
        self.builder = builder
    }
    
    func build() -> State {
        builder()
    }
}
