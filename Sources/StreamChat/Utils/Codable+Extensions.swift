//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - JSONDecoder Stream

extension JSONDecoder {
    /// A default `JSONDecoder`.
    static var `default`: JSONDecoder = stream
    
    /// A Stream Chat JSON decoder.
    static let stream: JSONDecoder = {
        let decoder = JSONDecoder()
        
        /// A custom decoding for a date.
        decoder.dateDecodingStrategy = .custom { decoder throws -> Date in
            let container = try decoder.singleValueContainer()
            var dateString: String = try container.decode(String.self)

            if let date = DateFormatter.Stream.rfc3339Date(from: dateString) {
                return date
            }

            // Fail
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
        }
        
        return decoder
    }()
}

// MARK: - JSONEncoder Stream

extension JSONEncoder {
    /// A default `JSONEncoder`.
    static var `default`: JSONEncoder = stream
    /// A default gzip `JSONEncoder`.
    static var defaultGzip: JSONEncoder = streamGzip
    
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
    /// A Stream Chat date formatters.
    enum Stream {
        // Creates and returns a date object from the specified RFC3339 formatted string representation.
        ///
        /// - Parameter string: The RFC3339 formatted string representation of a date.
        /// - Returns: A date object, or nil if no valid date was found.
        static func rfc3339Date(from string: String) -> Date? {
            let RFC3339TimezoneWrapper = "Z"

            // Formats according to samples
            // 2000-12-19T16:39:57-0800
            // 1934-01-01T12:00:27.87+0020
            // 1989-01-01T12:00:27
            let dateFormats = [
                "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ",
                "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ",
                "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
            ]

            let dateFormatter = Stream.gmtDateFormatter
            let uppercaseString = string.uppercased()

            let removedTimezoneWrapperString = uppercaseString.replacingOccurrences(of: RFC3339TimezoneWrapper, with: "-0000")

            for format in dateFormats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: removedTimezoneWrapperString) {
                    return date
                }
            }

            return nil
        }
        
        /// Creates and returns an RFC 3339 formatted string representation of the specified date.
        ///
        /// - Parameter date: The date to be represented.
        /// - Returns: A user-readable string representing the date.
        static func rfc3339DateString(from date: Date) -> String? {
            let dateFormatWithoutFractional = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            let dateFormatWithFractional = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            let nanosecondsInMillisecond = 1_000_000

            gmtDateFormatter.dateFormat = dateFormatWithoutFractional

            var gmtCalendar = Calendar(identifier: .iso8601)
            if let zeroTimezone = TimeZone(secondsFromGMT: 0) {
                gmtCalendar.timeZone = zeroTimezone
            }

            let components = gmtCalendar.dateComponents([.nanosecond], from: date)
            // If nanoseconds is more that 1 millisecond, use format with fractional seconds
            if let nanoseconds = components.nanosecond,
               nanoseconds >= nanosecondsInMillisecond {
                gmtDateFormatter.dateFormat = dateFormatWithFractional
            }

            return gmtDateFormatter.string(from: date)
        }

        private static let gmtDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter
        }()
    }
}

// MARK: - Helper AnyEncodable

struct AnyEncodable: Encodable {
    private let encodable: Encodable
    
    init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

extension Encodable {
    var asAnyEncodable: AnyEncodable {
        AnyEncodable(self)
    }
}
