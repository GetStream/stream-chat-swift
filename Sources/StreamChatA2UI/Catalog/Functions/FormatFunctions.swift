//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The formatting functions of the A2UI basic catalog.
///
/// A2UI has no operators, so agents use these functions for string
/// interpolation, number, currency and date formatting.
@available(iOS 15.0, macOS 12.0, *)
enum FormatFunctions {
    /// All formatting functions, in catalog order.
    static var all: [FunctionDefinition] {
        [formatString, formatNumber, formatCurrency, formatDate, pluralize]
    }

    /// Interpolates data model values and function results into a string.
    ///
    /// The template supports `${/absolute/path}`, `${relative/path}` and
    /// `${functionName(arg: value)}` expressions, and `\${` for a literal.
    static let formatString = FunctionDefinition(
        name: "formatString",
        description: """
        Performs string interpolation of data model values and other functions in the catalog functions list \
        and returns the resulting string. The value string can contain interpolated expressions in the \
        `${expression}` format. Supported expression types include: JSON Pointer paths to the data model \
        (e.g., `${/absolute/path}` or `${relative/path}`), and renderer-side function calls (e.g., `${now()}`). \
        Function arguments must be named (e.g., `${formatDate(value:${/currentDate}, format:'MM-dd')}`). \
        To include a literal `${` sequence, escape it as `\\${`.
        """,
        arguments: JsonSchema.object(
            properties: ["value": JsonSchema.dynamicString()],
            required: ["value"],
            additionalProperties: false
        ),
        returnType: .string
    ) { invocation in
        let template = try invocation.requireString("value")
        return try invocation.evaluateInterpolation(template)
    }

    /// Formats a number with grouping separators and a fixed precision.
    static let formatNumber = FunctionDefinition(
        name: "formatNumber",
        description: "Formats a number with the specified grouping and decimal precision.",
        arguments: JsonSchema.object(
            properties: [
                "value": JsonSchema.dynamicNumber(description: "The number to format."),
                "decimals": JsonSchema.dynamicNumber(description: "Optional. The number of decimal places to show."),
                "grouping": JsonSchema.dynamicBoolean(
                    description: "Optional. If true, uses locale-specific grouping separators. Defaults to true."
                )
            ],
            required: ["value"],
            additionalProperties: false
        ),
        returnType: .string
    ) { invocation in
        let value = try invocation.requireDouble("value")
        return numberFormatter(
            style: .decimal,
            currencyCode: nil,
            decimals: invocation.int("decimals"),
            grouping: invocation.bool("grouping") ?? true,
            locale: invocation.services.locale
        ).string(from: NSNumber(value: value)) ?? Json.stringify(value)
    }

    /// Formats a number as a localized currency amount.
    static let formatCurrency = FunctionDefinition(
        name: "formatCurrency",
        description: "Formats a number as a currency string.",
        arguments: JsonSchema.object(
            properties: [
                "value": JsonSchema.dynamicNumber(description: "The monetary amount."),
                "currency": JsonSchema.dynamicString(description: "The ISO 4217 currency code (e.g., 'USD', 'EUR')."),
                "decimals": JsonSchema.dynamicNumber(description: "Optional. The number of decimal places to show."),
                "grouping": JsonSchema.dynamicBoolean(
                    description: "Optional. If true, uses locale-specific grouping separators. Defaults to true."
                )
            ],
            required: ["value", "currency"],
            additionalProperties: false
        ),
        returnType: .string
    ) { invocation in
        let value = try invocation.requireDouble("value")
        let currency = try invocation.requireString("currency")
        return numberFormatter(
            style: .currency,
            currencyCode: currency,
            decimals: invocation.int("decimals"),
            grouping: invocation.bool("grouping") ?? true,
            locale: invocation.services.locale
        ).string(from: NSNumber(value: value)) ?? "\(currency) \(Json.stringify(value))"
    }

    /// Formats a date or timestamp with a Unicode TR35 pattern.
    ///
    /// Accepted input values are ISO 8601 strings, `yyyy-MM-dd` dates, `HH:mm`
    /// times and epoch timestamps in seconds or milliseconds.
    static let formatDate = FunctionDefinition(
        name: "formatDate",
        description: "Formats a timestamp into a string using a Unicode TR35 date pattern.",
        arguments: JsonSchema.object(
            properties: [
                "value": JsonSchema.dynamicValue(description: "The date to format."),
                "format": JsonSchema.dynamicString(description: "A Unicode TR35 date pattern string, e.g. 'MMM dd, yyyy'.")
            ],
            required: ["value", "format"],
            additionalProperties: false
        ),
        returnType: .string
    ) { invocation in
        let pattern = try invocation.requireString("format")
        guard let raw = invocation.value("value") else {
            throw A2UIFunctionError.missingArgument("value", function: "formatDate")
        }
        // A written date keeps the zone it was written in, so the same payload
        // shows the same time on every device; a date without a zone is a
        // wall-clock time. Only epoch timestamps use the device time zone.
        let timeZone = (raw as? String).map { A2UIDateParser.writtenTimeZone(of: $0) } ?? invocation.services.timeZone
        guard let date = A2UIDateParser.date(from: raw, timeZone: timeZone) else {
            return ""
        }
        if pattern == "ISO" {
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = timeZone
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.string(from: date)
        }
        let formatter = DateFormatter()
        formatter.locale = invocation.services.locale
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    /// Selects a string based on the plural category of a count.
    ///
    /// Foundation does not expose the CLDR plural rules, so the `zero`, `one`
    /// and `other` categories are selected and `other` is used as the fallback
    /// for every category a locale does not distinguish.
    static let pluralize = FunctionDefinition(
        name: "pluralize",
        description: """
        Returns a localized string based on the Common Locale Data Repository (CLDR) plural category of the \
        count (zero, one, two, few, many, other). Requires an 'other' fallback. For English, just use 'one' \
        and 'other'.
        """,
        arguments: JsonSchema.object(
            properties: [
                "value": JsonSchema.dynamicNumber(description: "The numeric value used to determine the plural category."),
                "zero": JsonSchema.dynamicString(description: "String for the 'zero' category."),
                "one": JsonSchema.dynamicString(description: "String for the 'one' category."),
                "two": JsonSchema.dynamicString(description: "String for the 'two' category."),
                "few": JsonSchema.dynamicString(description: "String for the 'few' category."),
                "many": JsonSchema.dynamicString(description: "String for the 'many' category."),
                "other": JsonSchema.dynamicString(description: "The default/fallback string.")
            ],
            required: ["value", "other"],
            additionalProperties: false
        ),
        returnType: .string
    ) { invocation in
        let value = try invocation.requireDouble("value")
        let other = try invocation.requireString("other")
        if value == 0, let zero = invocation.string("zero") { return zero }
        if abs(value) == 1, let one = invocation.string("one") { return one }
        if abs(value) == 2, let two = invocation.string("two") { return two }
        return other
    }

    private static func numberFormatter(
        style: NumberFormatter.Style,
        currencyCode: String?,
        decimals: Int?,
        grouping: Bool,
        locale: Locale
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = style
        formatter.usesGroupingSeparator = grouping
        if let currencyCode {
            formatter.currencyCode = currencyCode
        }
        if let decimals {
            let clamped = min(max(decimals, 0), 15)
            formatter.minimumFractionDigits = clamped
            formatter.maximumFractionDigits = clamped
        } else if style == .decimal {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 3
        }
        return formatter
    }
}

/// Parses the date representations accepted by A2UI payloads.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIDateParser {
    private static let patterns = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
        "yyyy-MM-dd'T'HH:mm:ssXXXXX",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd HH:mm",
        "yyyy-MM-dd",
        "HH:mm:ss",
        "HH:mm"
    ]

    /// The time zone a date string was written in.
    ///
    /// A trailing `Z` or `±hh:mm` offset names it; a string without one is a
    /// wall-clock time, read and formatted in UTC so it never shifts.
    static func writtenTimeZone(of string: String) -> TimeZone {
        let utc = TimeZone(secondsFromGMT: 0) ?? .current
        guard string.contains("T") || string.contains(" ") else { return utc }
        if string.hasSuffix("Z") || string.hasSuffix("z") { return utc }
        let pattern = "([+-])(\\d{2}):?(\\d{2})$"
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let signRange = Range(match.range(at: 1), in: string),
              let hoursRange = Range(match.range(at: 2), in: string),
              let minutesRange = Range(match.range(at: 3), in: string),
              let hours = Int(string[hoursRange]),
              let minutes = Int(string[minutesRange]) else {
            return utc
        }
        let seconds = (hours * 3600 + minutes * 60) * (string[signRange] == "-" ? -1 : 1)
        return TimeZone(secondsFromGMT: seconds) ?? utc
    }

    /// Converts a JSON value into a date.
    ///
    /// Numbers are treated as epoch seconds, or milliseconds when the value is
    /// large enough that seconds would be implausible.
    static func date(from value: (any Sendable)?, timeZone: TimeZone = .current) -> Date? {
        guard let value = Json.normalized(value) else { return nil }
        if let date = value as? Date { return date }

        if !(value is String), let number = Json.double(value) {
            let seconds = abs(number) > 100_000_000_000 ? number / 1000 : number
            return Date(timeIntervalSince1970: seconds)
        }
        guard let string = Json.string(value), !string.isEmpty else { return nil }
        if let date = A2UITimestamp.date(from: string) { return date }

        for pattern in patterns {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = timeZone
            formatter.isLenient = false
            formatter.dateFormat = pattern
            // A non-lenient formatter still rolls "2026-02-30" over to March, so
            // the date must format back to the string it was read from.
            if let date = formatter.date(from: string), formatter.string(from: date) == string { return date }
        }
        return nil
    }
}
