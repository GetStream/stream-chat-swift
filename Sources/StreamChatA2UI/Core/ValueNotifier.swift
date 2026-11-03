//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// An observable container for a single value.
///
/// Used for the small pieces of renderer state SwiftUI needs to observe
/// directly, such as whether a request is in flight or the current
/// conversation. Values must be read and written from the main thread.
@MainActor
final class ValueNotifier<Value>: ObservableObject {
    /// The current value, published to observers on change.
    @Published var value: Value

    /// Creates a notifier with an initial value.
    init(_ value: Value) {
        self.value = value
    }
}
