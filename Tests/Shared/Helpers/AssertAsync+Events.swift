//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

extension Assert {
    /// Periodically checks for the seeming equality of the provided collections of events. Fails if the collections
    /// are not equal within the `timeout` period.
    ///
    /// - Parameters:
    ///   - expression1: The first expression to evaluate.
    ///   - expression2: The first expression to evaluate.
    ///   - timeout: The maximum time the function waits for the expression results to equal.
    ///   - message: The message to print when the assertion fails.
    ///
    /// - Warning: ⚠️ Both expressions are evaluated repeatedly during the function execution. The expressions should not have
    ///   any side effects which can affect their results.
    static func willBeEqual(
        _ expression1: @autoclosure @escaping () -> [Event],
        _ expression2: @autoclosure @escaping () -> [Event],
        timeout: TimeInterval = defaultTimeout,
        message: @autoclosure @escaping () -> String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Assertion {
        var equatableCollection1: [EquatableEvent] { expression1().map(\.asEquatable) }
        var equatableCollection2: [EquatableEvent] { expression2().map(\.asEquatable) }
        
        // We can't use this as the default parameter because of the string interpolation.
        var defaultMessage: String {
            "\"\(equatableCollection1)\" not equal to \"\(equatableCollection2)\""
        }
        
        return willBeTrue(
            equatableCollection1 == equatableCollection2,
            timeout: timeout,
            message: message() ?? defaultMessage,
            file: file,
            line: line
        )
    }
}

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
