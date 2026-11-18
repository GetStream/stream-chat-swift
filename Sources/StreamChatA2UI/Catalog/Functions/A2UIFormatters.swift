//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Formatters and patterns the catalog's functions reuse: making one costs far more than using it,
// and a surface evaluates its bindings again on every change. The agent picks patterns and
// locales, so each cache is emptied once it holds `limit` entries.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
enum A2UIFormatters {
    static let posix = Locale(identifier: "en_US_POSIX")
    static let utc = TimeZone(secondsFromGMT: 0) ?? .current

    private static let limit = 64
    private static var dateFormatters: [String: DateFormatter] = [:]
    private static var numberFormatters: [String: NumberFormatter] = [:]
    private static var isoFormatters: [String: ISO8601DateFormatter] = [:]
    // Keyed by the pattern's bytes: Swift compares strings by canonical equivalence, so `[é]` and
    // `[e\u{301}]` are equal strings, but ICU reads them as different character classes.
    private static var expressions: [Data: NSRegularExpression] = [:]

    static func dateFormatter(pattern: String, locale: Locale, timeZone: TimeZone, isLenient: Bool = false) -> DateFormatter {
        let key = [pattern, locale.identifier, timeZone.identifier, String(isLenient)].joined(separator: "|")
        return cached(key, in: &dateFormatters) {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = timeZone
            formatter.isLenient = isLenient
            formatter.dateFormat = pattern
            return formatter
        }
    }

    static func numberFormatter(
        style: NumberFormatter.Style,
        currencyCode: String?,
        decimals: Int?,
        grouping: Bool,
        locale: Locale
    ) -> NumberFormatter {
        let key = [
            String(style.rawValue), currencyCode ?? "", decimals.map(String.init) ?? "", String(grouping), locale.identifier
        ].joined(separator: "|")
        return cached(key, in: &numberFormatters) {
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.numberStyle = style
            formatter.usesGroupingSeparator = grouping
            if let currencyCode {
                formatter.currencyCode = currencyCode
            }
            if let decimals {
                formatter.minimumFractionDigits = decimals
                formatter.maximumFractionDigits = decimals
            } else if style == .decimal {
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 3
            }
            return formatter
        }
    }

    static func isoFormatter(fractionalSeconds: Bool, timeZone: TimeZone) -> ISO8601DateFormatter {
        let key = [String(fractionalSeconds), timeZone.identifier].joined(separator: "|")
        return cached(key, in: &isoFormatters) {
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = timeZone
            formatter.formatOptions = fractionalSeconds ? [.withInternetDateTime, .withFractionalSeconds] : [.withInternetDateTime]
            return formatter
        }
    }

    static func expression(_ pattern: String) throws -> NSRegularExpression {
        let key = Data(pattern.utf8)
        if let expression = expressions[key] {
            return expression
        }
        let expression = try NSRegularExpression(pattern: pattern)
        if expressions.count >= limit {
            expressions.removeAll()
        }
        expressions[key] = expression
        return expression
    }

    private static func cached<Value>(_ key: String, in cache: inout [String: Value], make: () -> Value) -> Value {
        if let value = cache[key] {
            return value
        }
        let value = make()
        if cache.count >= limit {
            cache.removeAll()
        }
        cache[key] = value
        return value
    }
}
