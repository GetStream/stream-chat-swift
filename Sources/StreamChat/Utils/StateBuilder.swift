//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A builder for objects requiring @MainActor.
final class StateBuilder<State> {
    private var builder: (@MainActor() -> State)?
    
    init(builder: (@escaping @MainActor() -> State)) {
        self.builder = builder
    }
    
    @MainActor func build() -> State {
        guard let builder else {
            fatalError("Calling build multiple times for \(State.self)")
        }
        let state = builder()
        // Release retained values used by the builder
        self.builder = nil
        return state
    }
}
