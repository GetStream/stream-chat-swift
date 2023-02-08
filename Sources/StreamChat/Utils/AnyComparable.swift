//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// An instance of AnyComparable, can wrap any other instance(value or reference types).
/// If the wrapped value conforms to Comparable, then AnyComparable forwards the
/// equality and comparison checks to the value.
/// Otherwise, if value doesn't conform to Comparable then AnyComparable
/// returns false on any equality and comparison check.
///
/// >
/// When the value doesn't conform to Comparable, then the AnyComparable
/// will return false to equality and comparison(less  than) checks.
/// That will result in comparisons with operators `<=`, `>=`,`!=`
/// to succeed, as the rely on negating the outputs of either the equality or
/// the less-than check.
public struct AnyComparable: Comparable {
    private let value: Any
    private let less: (Any) -> Bool
    private let equals: (Any) -> Bool

    public init<E: Comparable>(
        _ value: E
    ) {
        self.value = value
        less = { ($0 as? E).map { unwrapped in value < unwrapped } ?? false }
        equals = { ($0 as? E == value) }
    }

    public init(
        _ value: Any
    ) {
        self.value = value
        less = { _ in false }
        equals = { _ in false }
    }

    public static func < (
        lhs: AnyComparable,
        rhs: AnyComparable
    ) -> Bool {
        lhs.less(rhs.value)
    }

    public static func == (
        lhs: AnyComparable,
        rhs: AnyComparable
    ) -> Bool {
        lhs.equals(rhs.value)
    }
}
