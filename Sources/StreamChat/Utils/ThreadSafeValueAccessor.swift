//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Provides thread-safe access to the provided value's storage
struct ThreadSafeValueAccessor<Value> {
    /// Describes the access level to a value's storage. Currently supports: .read, .write
    enum AccessLevel: Hashable { case read, write }

    /// The accessLevels that will be thread-safe when using this instance
    private let accessLevels: [AccessLevel]

    /// The queue that thread-safe access to the value's storage
    private var accessQueue: DispatchQueue

    private var _value: Value
    var value: Value {
        get { readValue() }
        set { writeValue(newValue) }
    }

    init(
        _ initialValue: Value,
        with accessLevels: [AccessLevel] = [.read, .write],
        queueLabel: String = "com.getstream.thread.safe.value.accessor.\(type(of: Value.self))",
        qos: DispatchQoS
    ) {
        _value = initialValue
        self.accessLevels = accessLevels
        accessQueue = .init(label: queueLabel, qos: qos)
    }

    private func readValue() -> Value {
        guard accessLevels.contains(.read) else {
            return _value
        }
        return accessQueue.sync { return _value }
    }

    private mutating func writeValue(_ newValue: Value) {
        guard accessLevels.contains(.write) else {
            _value = newValue
            return
        }
        accessQueue.sync {
            _value = newValue
        }
    }
}
