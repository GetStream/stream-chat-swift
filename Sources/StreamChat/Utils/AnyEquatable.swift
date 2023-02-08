//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// An instance of AnyEquatable, can wrap any instance.
/// If the wrapped value conforms to Equatable, then AnyEquatable forwards the
/// equality checks to the value.
/// Otherwise, if value doesn't conform to Equatable then AnyEquatable
/// returns false on any equality check.
public struct AnyEquatable: Equatable {
    private let value: Any
    private let equals: (Any) -> Bool

    public init<E: Equatable>(
        _ value: E
    ) {
        self.value = value
        equals = { ($0 as? E == value) }
    }

    public init(
        _ value: Any
    ) {
        self.value = value
        equals = { _ in false }
    }

    public static func == (
        lhs: AnyEquatable,
        rhs: AnyEquatable
    ) -> Bool {
        lhs.equals(rhs.value)
    }
}
