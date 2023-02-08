//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// An instance of AnyHashable, can wrap any instance.
/// If the wrapped value conforms to Hashable, then AnyHashable forwards the
/// equality checks and hashing requests to the value.
/// Otherwise, if value doesn't conform to Hashable then AnyHashable
/// returns false on any equality check and returns an always random
/// hashValue.
public struct AnyHashable: Hashable {
    private let value: Any
    private let hashIntoBlock: (inout Hasher) -> Void
    private let equals: (Any) -> Bool

    public init<E: Hashable>(
        _ value: E
    ) {
        self.value = value
        hashIntoBlock = { value.hash(into: &$0) }
        equals = { ($0 as? E == value) }
    }

    public init(
        _ value: Any
    ) {
        self.value = value
        hashIntoBlock = { $0.combine(String.newUniqueId) } // Combine with a unique value to avoid collisions on empty hashers
        equals = { _ in false }
    }

    public func hash(
        into hasher: inout Hasher
    ) {
        hashIntoBlock(&hasher)
    }

    public static func == (
        lhs: AnyHashable,
        rhs: AnyHashable
    ) -> Bool {
        lhs.equals(rhs.value)
    }
}
