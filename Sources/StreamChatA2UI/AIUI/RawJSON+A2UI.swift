//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatAI

@available(iOS 15.0, macOS 12.0, *)
extension RawJSON {
    /// A value of A2UI's data model or of a resolved property, as JSON.
    init(a2ui value: (any Sendable)?) {
        switch value {
        case let string as String:
            self = .string(string)
        case let number as NSNumber:
            // Booleans bridge to numbers too, which only their type tells apart.
            self = CFGetTypeID(number) == CFBooleanGetTypeID() ? .bool(number.boolValue) : .number(number.doubleValue)
        case let array as [any Sendable]:
            self = .array(array.map { RawJSON(a2ui: $0) })
        case let object as [String: any Sendable]:
            self = .dictionary(object.mapValues { RawJSON(a2ui: $0) })
        default:
            self = .nil
        }
    }

    /// The value as A2UI's data model holds it, with `null` as `NSNull`.
    var a2uiValue: any Sendable {
        switch self {
        case let .string(value): return value
        case let .number(value): return value
        case let .bool(value): return value
        case let .array(values): return values.map(\.a2uiValue)
        case let .dictionary(values): return values.mapValues(\.a2uiValue)
        case .nil: return NSNull()
        }
    }
}
