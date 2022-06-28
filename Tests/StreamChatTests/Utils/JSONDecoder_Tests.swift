//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class JSONDecoder_Tests: XCTestCase {
    private var decoder: JSONDecoder = .default

    func test_throwsException_whenDecodingDateFromEmptyString() {
        checkDecodingDateThrowException(dateString: "")
    }

    func test_throwsException_whenDecodingDateFromInvalidString() {
        checkDecodingDateThrowException(dateString: "123456")
    }

    func test_throwsException_whenDecodingDateFromNonRFC3339Date() {
        checkDecodingDateThrowException(dateString: "2020-09-30T19:51:17")
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithMilliseconds() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2020-08-24T17:28:04.123Z",
            year: 2020,
            month: 8,
            day: 24,
            hour: 17,
            minute: 28,
            second: 4,
            fractionalSeconds: 123
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithEmptyMilliseconds() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-12-02T15:11:12Z",
            year: 2002,
            month: 12,
            day: 2,
            hour: 15,
            minute: 11,
            second: 12
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithMinusTimezone() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-10-02T07:12:13-03:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithPlusTimezone() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-10-02T10:12:13+02:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 8,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithPlusZeroTimezone() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-10-02T10:12:13+00:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithMinusZeroTimezone() throws {
        try checkDateIsDecodingToComponents(
            dateString: "2002-10-02T10:12:13-00:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateBefore1970() throws {
        try checkDateIsDecodingToComponents(
            dateString: "1936-10-02T10:12:13Z",
            year: 1936,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }
    
    func test_defaultDecoder_isStreamDecoder() {
        // Assert that default decoder we use is the stream decoder
        XCTAssert(JSONDecoder.default === JSONDecoder.stream)
        XCTAssert(type(of: JSONDecoder.stream) == StreamJSONDecoder.self)
        
        // Assert the default parameters are correctly initialized
        XCTAssertEqual(JSONDecoder.stream.dateCache.countLimit, 5000)
        XCTAssertEqual(JSONDecoder.stream.iso8601formatter.formatOptions, [.withFractionalSeconds, .withInternetDateTime])
    }
    
    func test_datesAreCached() throws {
        final class ISO8601DateFormatter_Spy: ISO8601DateFormatter {
            var dateFromStringCalledCounter: Int = 0
            
            override func date(from string: String) -> Date? {
                dateFromStringCalledCounter += 1
                return super.date(from: string)
            }
        }
        
        final class NSCache_Spy: NSCache<NSString, NSDate> {
            var setObjectCalledCounter: Int = 0
            var getObjectCalledCounter: Int = 0
            
            override func object(forKey key: NSString) -> NSDate? {
                getObjectCalledCounter += 1
                return super.object(forKey: key)
            }
            
            override func setObject(_ obj: NSDate, forKey key: NSString) {
                setObjectCalledCounter += 1
                super.setObject(obj, forKey: key)
            }
        }
        
        // Given a decoder with spy dateFormatter and cache
        let dateFormatter = ISO8601DateFormatter_Spy()
        dateFormatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        let dateCache = NSCache_Spy()
        let decoder = StreamJSONDecoder(dateFormatter: dateFormatter, dateCache: dateCache)
        
        // When we decode a payload with repeated dates
        let repeatedDate = "2020-06-09T08:10:40.800912Z" // If you change this, make sure to change `actualDecodedDate` below
        let jsonPayload = """
            {
                "date1": "\(repeatedDate)",
                "date2": "\(repeatedDate)",
                "date3": "\(repeatedDate)",
                "date4": "\(repeatedDate)",
                "date5": "\(repeatedDate)"
            }
        """
        let dateDict = try decoder.decode([String: Date].self, from: jsonPayload.data(using: .utf8)!)
        
        // Then we should only decode the date once and use the cache
        XCTAssertEqual(dateFormatter.dateFromStringCalledCounter, 1)
        XCTAssertEqual(dateCache.setObjectCalledCounter, 1)
        XCTAssertEqual(dateCache.getObjectCalledCounter, 5)
        
        // The actual decoded date must match the date JSONDecoder decoded and cached
        let actualDecodedDate = Date(timeIntervalSince1970: 1_591_690_240.8)
        XCTAssertEqual(dateCache.object(forKey: repeatedDate as NSString)?.timeIntervalSince1970, actualDecodedDate.timeIntervalSince1970)
        
        // All dates must be decoded
        XCTAssertEqual(dateDict.keys.count, 5)
        for (_, value) in dateDict {
            XCTAssertEqual(value, actualDecodedDate)
        }
    }

    // MARK: Helpers

    private let dateKey = "date"
    
    private func json(dateString: String) -> String {
        "{\"\(dateKey)\":\"\(dateString)\"}"
    }

    private func checkDateIsDecodingToComponents(
        dateString: String,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        fractionalSeconds: Int? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        // Given
        let dateJson = json(dateString: dateString)
        let data = dateJson.data(using: .utf8)!

        // When
        let decoded: [String: Date] = try decoder.decode([String: Date].self, from: data)

        // Then
        let decodedDate = decoded[dateKey]!

        // Use GMT calendar, to test on GMT+0 timezone
        let components = Calendar.gmtCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: decodedDate
        )

        XCTAssertEqual(components.year, year, file: file, line: line)
        XCTAssertEqual(components.month, month, file: file, line: line)
        XCTAssertEqual(components.day, day, file: file, line: line)
        XCTAssertEqual(components.hour, hour, file: file, line: line)
        XCTAssertEqual(components.minute, minute, file: file, line: line)
        XCTAssertEqual(components.second, second, file: file, line: line)

        if let fractional = fractionalSeconds {
            let nanosecondsInMillisecond = 1_000_000
            let nanos = components.nanosecond!

            var fractionalResult = nanos / nanosecondsInMillisecond
            let modulo = nanos % nanosecondsInMillisecond

            if modulo > nanosecondsInMillisecond / 2 {
                fractionalResult += 1
            }

            XCTAssertEqual(fractionalResult, fractional, file: file, line: line)
        }
    }

    private func checkDecodingDateThrowException(dateString: String, file: StaticString = #filePath, line: UInt = #line) {
        // Given
        let dateJson = json(dateString: "")
        let data = dateJson.data(using: .utf8)!

        do {
            // When
            _ = try decoder.decode([String: Date].self, from: data)
        } catch {
            // Then
            XCTAssertNotNil(error, file: file, line: line)
        }
    }
}
