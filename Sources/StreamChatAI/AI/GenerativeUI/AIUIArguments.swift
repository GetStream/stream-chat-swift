//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Decodes the arguments an agent wrote for a component into the component's own type: keys in
/// snake_case, and dates as a day (`2026-11-14`, from its start in this device's time zone) or a
/// moment.
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
        return day(from: string)
    }

    // The start of a day written as `yyyy-MM-dd` and nothing else, when the calendar has it.
    private static func day(from string: String) -> Date? {
        let fields = string.split(separator: "-", omittingEmptySubsequences: false)
        guard fields.map(\.count) == [4, 2, 2],
              fields.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let year = Int(fields[0]), let month = Int(fields[1]), let day = Int(fields[2])
        else { return nil }
        let components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: .current,
            year: year,
            month: month,
            day: day
        )
        return components.isValidDate ? components.date : nil
    }
}
