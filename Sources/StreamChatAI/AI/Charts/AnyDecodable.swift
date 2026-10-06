//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct AnyDecodable: Decodable {
    public let value: Any
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Double.self) { value = v; return }
        if let v = try? c.decode(Int.self) { value = Double(v); return }
        if let v = try? c.decode(String.self) { value = v; return }
        if let v = try? c.decode(Bool.self) { value = v; return }
        if let v = try? c.decode([String: AnyDecodable].self) { value = v; return }
        if let v = try? c.decode([AnyDecodable].self) { value = v; return }
        value = NSNull()
    }

    public var string: String? { value as? String }
    public var double: Double? {
        if let d = value as? Double { return d }
        if let b = value as? Bool { return b ? 1 : 0 }
        return value as? Double
    }
}
