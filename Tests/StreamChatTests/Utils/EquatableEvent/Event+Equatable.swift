//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// A naive wrapper around `Event` to make them equatable.
///
/// ⚠️ Currently, it only uses `String(describing:)` to compare events. This will probably break in the future. If you
/// see any problems with `EquatableEvent`, inspect the custom implementation of `==` and tweak it the way it works as
/// expected.
struct EquatableEvent: Equatable {
    let event: Event
    init(event: Event) {
        self.event = event
    }

    static func == (lhs: EquatableEvent, rhs: EquatableEvent) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}

extension Array where Element: Event {
    func asEquatable() -> [EquatableEvent] {
        map(EquatableEvent.init)
    }
}

extension Event {
    var asEquatable: EquatableEvent {
        EquatableEvent(event: self)
    }
}
