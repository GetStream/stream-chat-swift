//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import XCTest

final class DefaultScheduledMessageDateFormatter_Tests: XCTestCase {
    private var calendar: Calendar!
    private var locale: Locale!
    private var subject: DefaultScheduledMessageDateFormatter!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 3 * 3600)!
        locale = Locale(identifier: "en_GB")
        subject = DefaultScheduledMessageDateFormatter(calendar: calendar, locale: locale)
    }

    override func tearDown() {
        subject = nil
        calendar = nil
        locale = nil
        super.tearDown()
    }

    // MARK: - format(_:)

    func test_format_sameDay_returnsToday() {
        XCTAssertEqual(subject.format(date(daysFromNow: 0, hour: 23)), "Today at 23:00")
    }

    func test_format_startOfTheNextDayInTheTimeZoneOfTheCalendar_returnsTomorrow() {
        XCTAssertEqual(subject.format(date(daysFromNow: 1, hour: 0, minute: 30)), "Tomorrow at 00:30")
    }

    func test_format_twoDaysAhead_returnsTheWeekday() {
        let date = date(daysFromNow: 2, hour: 9)
        XCTAssertEqual(subject.format(date), "\(expected(date, template: "EEEE")) at 09:00")
    }

    func test_format_sixDaysAhead_returnsTheWeekday() {
        let date = date(daysFromNow: 6, hour: 9)
        XCTAssertEqual(subject.format(date), "\(expected(date, template: "EEEE")) at 09:00")
    }

    func test_format_sevenDaysAhead_returnsTheDay() {
        let date = date(daysFromNow: 7, hour: 9)
        XCTAssertEqual(subject.format(date), "\(expected(date, template: dayTemplate(for: date))) at 09:00")
    }

    func test_format_pastDay_returnsTheDay() {
        let date = date(daysFromNow: -1, hour: 9)
        XCTAssertEqual(subject.format(date), "\(expected(date, template: dayTemplate(for: date))) at 09:00")
    }

    func test_format_inALocaleWithLowercaseDays_capitalizesTheDay() {
        locale = Locale(identifier: "et_EE")
        subject = DefaultScheduledMessageDateFormatter(calendar: calendar, locale: locale)
        let weekday = date(daysFromNow: 2, hour: 9)
        XCTAssertEqual(subject.format(date(daysFromNow: 1, hour: 9)), "Homme at 09:00")
        XCTAssertEqual(subject.format(weekday), "\(expected(weekday, template: "EEEE").capitalized) at 09:00")
    }

    // MARK: - formatAbsolute(_:)

    func test_formatAbsolute_sameDay_returnsTheDay() {
        let date = date(daysFromNow: 0, hour: 23)
        XCTAssertEqual(subject.formatAbsolute(date), "\(expected(date, template: dayTemplate(for: date))) at 23:00")
    }

    func test_formatAbsolute_anotherYear_returnsTheDayWithTheYear() {
        let date = date(daysFromNow: 400, hour: 9)
        XCTAssertEqual(subject.formatAbsolute(date), "\(expected(date, template: "EEEMMMdy")) at 09:00")
    }

    // MARK: - formatTimeZone(_:)

    func test_formatTimeZone_returnsTheShortOffset() {
        XCTAssertEqual(subject.formatTimeZone(TimeZone(secondsFromGMT: 3 * 3600)!), "GMT+3")
        XCTAssertEqual(subject.formatTimeZone(TimeZone(secondsFromGMT: -(5 * 3600 + 1800))!), "GMT-5:30")
    }

    // MARK: - Helpers

    private func date(daysFromNow days: Int, hour: Int, minute: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: days, to: Date())!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    private func dayTemplate(for date: Date) -> String {
        calendar.isDate(date, equalTo: Date(), toGranularity: .year) ? "EEEMMMd" : "EEEMMMdy"
    }

    private func expected(_ date: Date, template: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
}
