//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing
@MainActor
private func callFunction(_ definition: FunctionDefinition, _ arguments: JsonMap) -> (any Sendable)? {
    let (evaluator, model) = makeEvaluator(catalogs: [BasicCatalog.catalog], surfaceCatalogId: BasicCatalog.catalogId)
    let context = DataContext(model, "/")
    return evaluator.execute(definition, arguments: evaluator.resolveArguments(arguments, in: context), in: context)
}

@MainActor
@Suite("Catalog edge cases")
struct CatalogEdgeCaseTests {
    @Test("A slider's value keeps to its step without floating-point noise")
    func sliderRounding() {
        let range = A2UISliderView.range(minimum: 0, maximum: 1)
        let step = A2UISliderView.step(in: range, steps: 10)

        #expect(A2UISliderView.rounded(0.30000000000000004, in: range, step: step) == 0.3)
        #expect(A2UISliderView.rounded(0.34, in: range, step: step) == 0.3)
        #expect(A2UISliderView.rounded(2, in: range, step: step) == 1)
        #expect(A2UISliderView.rounded(37.28799819946289, in: 0...100, step: nil) == 37.29)
        #expect(A2UISliderView.rounded(.nan, in: 0...100, step: nil) == 0)
    }

    @Test("A DateTimeInput without either flag writes a date, and a time-only one a time")
    func dateTimeFormats() {
        let date = Date(timeIntervalSince1970: 1_795_000_000)
        let zone = TimeZone(identifier: "America/Los_Angeles") ?? .current

        #expect(A2UIDateTimeInputView.format(date, showsDate: true, showsTime: false, timeZone: zone).count == 10)
        #expect(A2UIDateTimeInputView.format(date, showsDate: false, showsTime: true, timeZone: zone).count == 8)
        #expect(A2UIDateTimeInputView.format(date, showsDate: true, showsTime: true, timeZone: zone).hasSuffix("Z"))
    }

    @Test("Times without a date compare on the day they are read on")
    func timeOnlyBounds() {
        let utc = TimeZone(secondsFromGMT: 0) ?? .current
        let lower = A2UIDateParser.date(from: "09:00", timeZone: utc)
        let upper = A2UIDateParser.date(from: "17:00", timeZone: utc)
        let noon = A2UIDateParser.date(from: "12:00:00", timeZone: utc)

        #expect(noon.map { A2UIDateTimeInputView.shown($0, in: (lower, upper)) } == noon)
    }

    @Test("test_evaluate_function_format_date_iso_utc: ISO dates are written in UTC")
    func isoInUTC() {
        let formatted = callFunction(FormatFunctions.formatDate, ["value": "2026-09-04T23:30:00-05:00", "format": "ISO"])

        #expect(Json.string(formatted) == "2026-09-05T04:30:00.000Z")
    }

    @Test("regex rejects patterns that are too long or repeat an unbounded group, and long values don't match")
    func regexSafety() {
        #expect(A2UIRegexSafety.problem(in: "^\\d{10}$") == nil)
        #expect(A2UIRegexSafety.problem(in: "^\\+?[0-9]{10,15}$") == nil)
        #expect(A2UIRegexSafety.problem(in: "^(a|b)?c$") == nil)
        #expect(A2UIRegexSafety.problem(in: "^(a+)+$") != nil)
        #expect(A2UIRegexSafety.problem(in: "^([a-zA-Z0-9]+\\s?)*$") != nil)
        #expect(A2UIRegexSafety.problem(in: "(?:x*){2}") != nil)
        #expect(A2UIRegexSafety.problem(in: "(a)\\1") != nil)
        #expect(A2UIRegexSafety.problem(in: "(?<=a)b") != nil)
        #expect(A2UIRegexSafety.problem(in: String(repeating: "a", count: 257)) != nil)

        let value = String(repeating: "a", count: 4097)
        #expect(!ValidationResult(coercing: callFunction(ValidationFunctions.regex, ["value": value, "pattern": "a"])).isValid)
    }

    @Test("A media link is trimmed, has its spaces encoded and needs a scheme")
    func mediaLinks() {
        #expect(A2UIImageView.link("  https://ex.com/my photo.jpg ")?.absoluteString == "https://ex.com/my%20photo.jpg")
        #expect(A2UIImageView.link("AppIcon") == nil)
        #expect(A2UIImageView.link("") == nil)
    }

    @Test("Values read as DynamicBoolean follow the specification's table")
    func dynamicBooleans() {
        #expect(Json.dynamicBool(true) == true)
        #expect(Json.dynamicBool("FALSE") == false)
        #expect(Json.dynamicBool("hello") == false)
        #expect(Json.dynamicBool(0) == false)
        #expect(Json.dynamicBool(2) == true)
        #expect(Json.dynamicBool(["valid": true] as JsonMap) == true)
        #expect(Json.dynamicBool(["other": true] as JsonMap) == false)
        #expect(Json.dynamicBool([1] as JsonArray) == false)
        #expect(Json.dynamicBool(nil) == nil)
    }
}
