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
            
            if !dateString.contains(".") {
                dateString.removeLast()
                dateString.append(".0Z")
            }
            
            if let date = DateFormatter.Stream.iso8601Date(from: dateString) {
                return date
            }
            
            if dateString.hasPrefix("1970-01-01T00:00:00") {
                log.warning("⚠️ Invalid ISO8601 date: \(dateString)")
                return Date()
            }
            
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
            try container.encode(DateFormatter.Stream.iso8601DateString(from: date))
        }
    }
}

// MARK: - Date Formatter Helper

extension DateFormatter {
    /// A Stream Chat date formatters.
    enum Stream {
        /// Creates and returns a date object from the specified ISO 8601 formatted string representation.
        ///
        /// - Parameter string: The ISO 8601 formatted string representation of a date.
        /// - Returns: A date object, or nil if no valid date was found.
        static func iso8601Date(from string: String) -> Date? {
            if #available(iOS 11.2, macOS 10.13, *) {
                return Stream.iso8601DateFormatter.date(from: string)
            }
            
            return Stream.dateFormatter.date(from: string)
        }
        
        /// Creates and returns an ISO 8601 formatted string representation of the specified date.
        ///
        /// - Parameter date: The date to be represented.
        /// - Returns: A user-readable string representing the date.
        static func iso8601DateString(from date: Date) -> String? {
            if #available(iOS 11.2, macOS 10.13, *) {
                return Stream.iso8601DateFormatter.string(from: date)
            }
            
            return Stream.dateFormatter.string(from: date)
        }
        
        private static let iso8601DateFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }()
        
        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
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
