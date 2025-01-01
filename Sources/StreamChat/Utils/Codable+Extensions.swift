//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - JSONDecoder Stream

final class StreamJSONDecoder: JSONDecoder, @unchecked Sendable {
    let iso8601formatter: ISO8601DateFormatter
    let dateCache: NSCache<NSString, NSDate>
    let rawJSONCache: RawJSONCache

    override convenience init() {
        let iso8601formatter = ISO8601DateFormatter()
        iso8601formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]

        let dateCache = NSCache<NSString, NSDate>()
        dateCache.countLimit = 5000 // We cache at most 5000 dates, which gives good enough performance

        self.init(
            dateFormatter: iso8601formatter,
            dateCache: dateCache,
            rawJSONCache: RawJSONCache(countLimit: 500)
        )
    }

    init(
        dateFormatter: ISO8601DateFormatter,
        dateCache: NSCache<NSString, NSDate>,
        rawJSONCache: RawJSONCache
    ) {
        iso8601formatter = dateFormatter
        self.dateCache = dateCache
        self.rawJSONCache = rawJSONCache

        super.init()

        dateDecodingStrategy = .custom { [weak self] decoder throws -> Date in
            let container = try decoder.singleValueContainer()
            let dateString: String = try container.decode(String.self)

            if let date = self?.dateCache.object(forKey: dateString as NSString) {
                return date.bridgeDate
            }

            if let date = self?.iso8601formatter.dateWithMicroseconds(from: dateString) {
                self?.dateCache.setObject(date.bridgeDate, forKey: dateString as NSString)
                return date
            }

            if let date = DateFormatter.Stream.rfc3339Date(from: dateString) {
                self?.dateCache.setObject(date.bridgeDate, forKey: dateString as NSString)
                return date
            }

            // Fail
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
        }
    }
}

extension StreamJSONDecoder {
    class RawJSONCache {
        private let storage: NSCache<NSNumber, BoxedRawJSON>
        
        init(countLimit: Int) {
            storage = NSCache()
            storage.countLimit = countLimit
        }
        
        func rawJSON(forKey key: Int) -> [String: RawJSON]? {
            storage.object(forKey: key as NSNumber)?.value
        }
        
        func setRawJSON(_ value: [String: RawJSON], forKey key: Int) {
            storage.setObject(BoxedRawJSON(value: value), forKey: key as NSNumber)
        }
        
        final class BoxedRawJSON {
            let value: [String: RawJSON]
            
            init(value: [String: RawJSON]) {
                self.value = value
            }
        }
    }
    
    /// A convenience method returning decoded RawJSON dictionary with caching enabled.
    ///
    /// Extra data stored in models can be large, what can significantly slow
    /// down DTO to model conversions. This function is a convenient way for
    /// caching some of the data in DTO to model conversions.
    func decodeCachedRawJSON(from data: Data?) throws -> [String: RawJSON] {
        guard let data, !data.isEmpty else { return [:] }
        let key = data.hashValue
        if let value = rawJSONCache.rawJSON(forKey: key) {
            return value
        }
        let rawJSON = try decode([String: RawJSON].self, from: data)
        rawJSONCache.setRawJSON(rawJSON, forKey: key)
        return rawJSON
    }
}

extension JSONDecoder {
    /// A default `JSONDecoder`.
    static let `default`: JSONDecoder = stream

    /// A Stream Chat JSON decoder.
    static let stream: StreamJSONDecoder = {
        StreamJSONDecoder()
    }()
}

// MARK: - JSONEncoder Stream

extension JSONEncoder {
    /// A default `JSONEncoder`.
    static let `default`: JSONEncoder = stream
    /// A default gzip `JSONEncoder`.
    static let defaultGzip: JSONEncoder = streamGzip

    /// A Stream Chat JSON encoder.
    static let stream: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .stream
        return encoder
    }()

    /// A Stream Chat JSON encoder with a gzipped content.
    static let streamGzip: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .gzip
        encoder.dateEncodingStrategy = .stream
        return encoder
    }()
}

extension JSONEncoder.DataEncodingStrategy {
    // Gzip data encoding.
    static var gzip: JSONEncoder.DataEncodingStrategy {
        .custom { data, encoder throws in
            var container = encoder.singleValueContainer()
            let gzippedData = try data.gzipped()
            try container.encode(gzippedData)
        }
    }
}

extension JSONEncoder.DateEncodingStrategy {
    /// A Stream encoding for the custom ISO8601 date.
    static var stream: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder throws in
            var container = encoder.singleValueContainer()
            try container.encode(DateFormatter.Stream.rfc3339DateString(from: date))
        }
    }
}

// MARK: - Date Formatter Helper

extension DateFormatter {
    /// Stream Chat date formatters.
    enum Stream {
        // Creates and returns a date object from the specified RFC3339 formatted string representation.
        ///
        /// - Parameter string: The RFC3339 formatted string representation of a date.
        /// - Returns: A date object, or nil if no valid date was found.
        static func rfc3339Date(from string: String) -> Date? {
            let RFC3339TimezoneWrapper = "Z"
            let uppercaseString = string.uppercased()
            let removedTimezoneWrapperString = uppercaseString.replacingOccurrences(of: RFC3339TimezoneWrapper, with: "-0000")
            return gmtDateFormatters.lazy.compactMap { $0.date(from: removedTimezoneWrapperString) }.first
        }

        /// Creates and returns an RFC 3339 formatted string representation of the specified date.
        ///
        /// - Parameter date: The date to be represented.
        /// - Returns: A user-readable string representing the date.
        static func rfc3339DateString(from date: Date) -> String? {
            let nanosecondsInMillisecond = 1_000_000

            var gmtCalendar = Calendar(identifier: .iso8601)
            if let zeroTimezone = TimeZone(secondsFromGMT: 0) {
                gmtCalendar.timeZone = zeroTimezone
            }

            let components = gmtCalendar.dateComponents([.nanosecond], from: date)
            // If nanoseconds is more that 1 millisecond, use format with fractional seconds
            guard let nanoseconds = components.nanosecond,
                  nanoseconds >= nanosecondsInMillisecond
            else {
                return dateFormatterWithoutFractional.string(from: date)
            }

            return dateFormatterWithFractional.string(from: date)
        }

        // Formats according to samples
        // 2000-12-19T16:39:57-0800
        // 1934-01-01T12:00:27.87+0020
        // 1989-01-01T12:00:27
        private static let gmtDateFormatters: [DateFormatter] = [
            "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ",
            "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ",
            "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
        ].map(makeDateFormatter)

        private static let dateFormatterWithoutFractional = makeDateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
        private static let dateFormatterWithFractional = makeDateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX")

        private static func makeDateFormatter(dateFormat: String) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = dateFormat
            return formatter
        }
    }
}

extension ISO8601DateFormatter {
    func dateWithMicroseconds(from string: String) -> Date? {
        guard let date = date(from: string) else { return nil }
        // Manually parse microseconds and nanoseconds, because ISO8601DateFormatter is limited to ms.
        // Note that Date's timeIntervalSince1970 rounds to 0.000_000_1
        guard let index = string.lastIndex(of: ".") else { return date }
        let range = string.suffix(from: index)
            .dropFirst(4) // . and ms part
            .dropLast() // Z
        var fractionWithoutMilliseconds = String(range)
        if fractionWithoutMilliseconds.count < 3 {
            fractionWithoutMilliseconds = fractionWithoutMilliseconds.padding(toLength: 3, withPad: "0", startingAt: 0)
        }
        guard let microseconds = TimeInterval("0.000".appending(fractionWithoutMilliseconds)) else { return date }
        return Date(timeIntervalSince1970: date.timeIntervalSince1970 + microseconds)
    }
}

// MARK: - Helper AnyEncodable

struct AnyEncodable: Encodable {
    let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try encodable.encode(to: &container)
    }
}

extension Encodable {
    var asAnyEncodable: AnyEncodable {
        AnyEncodable(self)
    }

    // We need this helper in order to encode AnyEncodable with a singleValueContainer,
    // this is needed for the encoder to apply the encoding strategies of the inner type (encodable).
    // More details about this in the following thread:
    // https://forums.swift.org/t/how-to-encode-objects-of-unknown-type/12253/10
    fileprivate func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}
