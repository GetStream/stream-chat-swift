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

    func test_decodes_whenDecodingDateFromRFC3339DateWithMilliseconds() {
        checkDateIsDecodingToComponents(
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

    func test_decodes_whenDecodingDateFromRFC3339DateWithEmptyMilliseconds() {
        checkDateIsDecodingToComponents(
            dateString: "2002-12-02T15:11:12Z",
            year: 2002,
            month: 12,
            day: 2,
            hour: 15,
            minute: 11,
            second: 12
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithMinusTimezone() {
        checkDateIsDecodingToComponents(
            dateString: "2002-10-02T07:12:13-03:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithPlusTimezone() {
        checkDateIsDecodingToComponents(
            dateString: "2002-10-02T10:12:13+02:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 8,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithPlusZeroTimezone() {
        checkDateIsDecodingToComponents(
            dateString: "2002-10-02T10:12:13+00:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateFromRFC3339DateWithMinusZeroTimezone() {
        checkDateIsDecodingToComponents(
            dateString: "2002-10-02T10:12:13-00:00",
            year: 2002,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }

    func test_decodes_whenDecodingDateBefore1970() {
        checkDateIsDecodingToComponents(
            dateString: "1936-10-02T10:12:13Z",
            year: 1936,
            month: 10,
            day: 2,
            hour: 10,
            minute: 12,
            second: 13
        )
    }
    
    func test_userPayloadCaching_isThreadSafe() {
        for offset in 0..<100 {
            DispatchQueue.random.asyncAfter(deadline: .now() + .milliseconds(offset % 100)) { [decoder] in
                let payloadTuple = self.userPayloadJSON()
                do {
                    let userPayload = try decoder.decode(UserPayload.self, from: payloadTuple.payloadJSON.data(using: .utf8)!)
                    XCTAssertEqual(userPayload.name, payloadTuple.name)
                } catch {
                    XCTFail("Failed to decode JSON: \(payloadTuple), error: \(error)")
                }
            }
        }
    }

    // MARK: Helpers
    
    private func userPayloadJSON() -> (payloadJSON: String, name: String) {
        let name = String.unique
        return ("""
         {
            "id" : "broken-waterfall-5",
            "banned" : false,
            "unread_channels" : 0,
            "totalUnreadCount" : 0,
            "last_active" : "2020-06-10T13:24:00.501797Z",
            "created_at" : "2019-12-12T15:33:46.488935Z",
            "unreadChannels" : 0,
            "unread_count" : 0,
            "image" : "https://getstream.io/random_svg/?id=broken-waterfall-5&amp;name=Broken+waterfall",
            "updated_at" : "2020-06-10T14:11:29.946106Z",
            "role" : "user",
            "total_unread_count" : 0,
            "online" : true,
            "name" : "\(name)"
          }
        """, name)
    }

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
        fractionalSeconds: Int? = nil
    ) {
        // Given
        let dateJson = json(dateString: dateString)
        let data = dateJson.data(using: .utf8)!

        // When
        let decoded: [String: Date] = try! decoder.decode([String: Date].self, from: data)

        // Then
        let decodedDate = decoded[dateKey]!

        // Use GMT calendar, to test on GMT+0 timezone
        let components = Calendar.gmtCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: decodedDate
        )

        XCTAssertEqual(components.year, year)
        XCTAssertEqual(components.month, month)
        XCTAssertEqual(components.day, day)
        XCTAssertEqual(components.hour, hour)
        XCTAssertEqual(components.minute, minute)
        XCTAssertEqual(components.second, second)

        if let fractional = fractionalSeconds {
            let nanosecondsInMillisecond = 1_000_000
            let nanos = components.nanosecond!

            var fractionalResult = nanos / nanosecondsInMillisecond
            let modulo = nanos % nanosecondsInMillisecond

            if modulo > nanosecondsInMillisecond / 2 {
                fractionalResult += 1
            }

            XCTAssertEqual(fractionalResult, fractional)
        }
    }

    private func checkDecodingDateThrowException(dateString: String) {
        // Given
        let dateJson = json(dateString: "")
        let data = dateJson.data(using: .utf8)!

        do {
            // When
            _ = try decoder.decode([String: Date].self, from: data)
        } catch {
            // Then
            XCTAssertNotNil(error)
        }
    }
}
