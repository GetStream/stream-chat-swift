//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A builder for objects requiring @MainActor.
struct StateBuilder<State: Sendable>: Sendable {
    private var builder: ((@Sendable @MainActor () -> State))?
    @MainActor private var _state: State?
    
    init(builder: (@escaping @Sendable @MainActor () -> State)) {
        self.builder = builder
    }
    
    @MainActor mutating func state() -> State {
        if let _state { return _state }
        let state = builder!()
        _state = state
        // Release captured values in the closure
        builder = nil
        return state
    }
}
