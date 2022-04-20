//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class JSONEncoderTests: XCTestCase {
    private var encoder: JSONEncoder!

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }()

    override func setUp() {
        encoder = .default
        super.setUp()
    }

    override func tearDown() {
        encoder = nil
        super.tearDown()
    }

    func testAnyEncodablePreservesEncodingStrategies() throws {
        let isoDate = "2020-04-14T10:10:00+0000"
        let date = dateFormatter.date(from: isoDate)!

        let dic: [String: AnyEncodable] = ["created_at": date.asAnyEncodable]
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(dic)
        let jsonString = String(data: jsonData, encoding: .utf8)
        XCTAssertEqual(jsonString, "{\"created_at\":\"2020-04-14T10:10:00Z\"}")
    }

    func test_encodes_whenEncodingDateToRFC3339DateWithMilliseconds() {
        checkDateIsEncodingFromComponents(
            year: 2020,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13,
            milliseconds: 123,
            timezoneHours: 0,
            dateString: "2020-10-02T10:12:13.123Z"
        )
    }

    func test_encodes_whenEncodingDateToRFC3339DateWithEmptyMilliseconds() {
        checkDateIsEncodingFromComponents(
            year: 2020,
            month: 11,
            day: 3,
            hour: 11,
            minute: 12,
            second: 56,
            timezoneHours: 0,
            dateString: "2020-11-03T11:12:56Z"
        )
    }

    func test_encodes_whenEncodingDateToRFC3339DateWithPlusTimezone() {
        checkDateIsEncodingFromComponents(
            year: 2019,
            month: 8,
            day: 15,
            hour: 12,
            minute: 13,
            second: 42,
            timezoneHours: 2,
            dateString: "2019-08-15T10:13:42Z"
        )
    }

    func test_encodes_whenEncodingDateToRFC3339DateWithMinusTimezone() {
        checkDateIsEncodingFromComponents(
            year: 2018,
            month: 7,
            day: 28,
            hour: 5,
            minute: 47,
            second: 42,
            timezoneHours: -3,
            dateString: "2018-07-28T08:47:42Z"
        )
    }
    
    func test_encodes_whenEncodingDateBefore1970() {
        checkDateIsEncodingFromComponents(
            year: 1936,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13,
            timezoneHours: 0,
            dateString: "1936-10-02T10:12:13Z"
        )
    }
}

// MARK: Test Helpers

extension JSONEncoderTests {
    private func checkDateIsEncodingFromComponents(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        milliseconds: Int? = nil,
        timezoneHours: Int,
        dateString: String
    ) {
        // Given
        let secondsInMinute = 60
        let minutesInHour = 60
        let nanosecondsInMillisecond = 1_000_000
        let jsonEncodingStringWrapper = "\""

        var resultMilliseconds: Int? = milliseconds
        if let millis = milliseconds {
            resultMilliseconds = millis * nanosecondsInMillisecond
        }

        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: timezoneHours * secondsInMinute * minutesInHour),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            nanosecond: resultMilliseconds
        )

        // Use GMT calendar, to test on GMT+0 timezone
        let date: Date = Calendar.gmtCalendar.date(from: components)!

        // When
        let encodedData: Data = try! encoder.encode(date)
        var resultString = String(data: encodedData, encoding: .utf8)

        // Remove JSON string wrapper (quote)
        resultString = resultString?.replacingOccurrences(of: jsonEncodingStringWrapper, with: "")

        // Then
        XCTAssertEqual(resultString, dateString)
    }
}
