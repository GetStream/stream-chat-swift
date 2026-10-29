//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Decodes the arguments an agent wrote for a component into the component's own type: keys in
/// snake_case, and dates as a day (`2026-11-14`, on this device's calendar) or a moment.
enum AIUIArguments {
    static func decode<Value: Decodable>(_ type: Value.Type, from arguments: [String: RawJSON]) throws -> Value {
        let data = try JSONEncoder().encode(arguments)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = Self.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a date: \(string)")
            }
            return date
        }
        return try decoder.decode(Value.self, from: data)
    }

    static func date(from string: String) -> Date? {
        if let moment = RFC3339DateFormatter.date(from: string) {
            return moment
        }
        return try? Date.ISO8601FormatStyle(timeZone: .current).year().month().day().parse(string)
    }
}
