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

    @Test("A slider over a tiny range keeps its values apart")
    func sliderOverATinyRange() {
        let range = A2UISliderView.range(minimum: 0, maximum: 0.0000001)
        let step = A2UISliderView.step(in: range, steps: 2)

        #expect(A2UISliderView.rounded(0.0000001, in: range, step: step) == 0.0000001)
        #expect(A2UISliderView.rounded(0.00000004, in: range, step: step) == 0.00000005)
        #expect(A2UISliderView.rounded(0.0000001, in: range, step: nil) == 0.0000001)
        #expect(A2UISliderView.rounded(0.000000033, in: range, step: nil) == 0.000000033)
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
    func timeOnlyBounds() throws {
        let utc = TimeZone(secondsFromGMT: 0) ?? .current
        let lower = try #require(A2UIDateParser.date(from: "09:00", timeZone: utc))
        let upper = try #require(A2UIDateParser.date(from: "17:00", timeZone: utc))
        let noon = try #require(A2UIDateParser.date(from: "12:00:00", timeZone: utc))
        let early = try #require(A2UIDateParser.date(from: "08:30:00", timeZone: utc))
        let late = try #require(A2UIDateParser.date(from: "18:00", timeZone: utc))

        #expect(A2UIDateTimeInputView.shown(noon, in: (lower, upper)) == noon)
        #expect(A2UIDateTimeInputView.shown(early, in: (lower, upper)) == lower)
        #expect(A2UIDateTimeInputView.shown(late, in: (lower, upper)) == upper)
    }

    @Test("A date-only input's bounds are the days they fall on, so the day it writes stays in them")
    func dateOnlyBounds() throws {
        let utc = TimeZone(secondsFromGMT: 0) ?? .current
        let range = A2UIDateTimeInputView.range(
            minimum: "2026-04-01T12:00:00Z",
            maximum: "2026-04-03T08:00:00Z",
            timeZone: utc,
            showsTime: false
        )
        let lower = try #require(range.lower)
        let shown = A2UIDateTimeInputView.shown(TestServices.referenceDate, in: range)
        let written = A2UIDateTimeInputView.format(shown, showsDate: true, showsTime: false, timeZone: utc)

        #expect(written == "2026-04-01")
        #expect(try #require(A2UIDateParser.date(from: written, timeZone: utc)) >= lower)
        #expect(range.upper == A2UIDateParser.date(from: "2026-04-03", timeZone: utc))

        let withTime = A2UIDateTimeInputView.range(minimum: "2026-04-01T12:00:00Z", maximum: nil, timeZone: utc, showsTime: true)
        #expect(withTime.lower == A2UIDateParser.date(from: "2026-04-01T12:00:00Z", timeZone: utc))
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

    @Test("test_evaluate_function_regex_v10_value_exceeding_4096_code_points_returns_invalid, even with a pattern that is too long")
    func longValueBeforeLongPattern() {
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(catalogs: [BasicCatalog.catalog], surfaceCatalogId: BasicCatalog.catalogId, router: router)
        let context = DataContext(model, "/")
        let arguments: JsonMap = ["value": String(repeating: "a", count: 4097), "pattern": String(repeating: "a", count: 257)]

        let result = evaluator.execute(ValidationFunctions.regex, arguments: evaluator.resolveArguments(arguments, in: context), in: context)

        #expect(!ValidationResult(coercing: result).isValid)
        #expect(router.errors.isEmpty)
    }

    @Test("A pattern too long to use isn't copied into its error")
    func longPatternError() {
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(catalogs: [BasicCatalog.catalog], surfaceCatalogId: BasicCatalog.catalogId, router: router)
        let context = DataContext(model, "/")
        let arguments: JsonMap = ["value": "a", "pattern": String(repeating: "a", count: 10000)]

        _ = evaluator.execute(ValidationFunctions.regex, arguments: evaluator.resolveArguments(arguments, in: context), in: context)

        #expect(router.errors.map(\.message) == ["regex can't use its pattern: it is longer than 256 characters."])
    }

    @Test("A character class can't hold an escape the regex dialect leaves out")
    func regexEscapesInClasses() {
        #expect(A2UIRegexSafety.problem(in: "[\\p{L}]") != nil)
        #expect(A2UIRegexSafety.problem(in: "[\\1]") != nil)
        #expect(A2UIRegexSafety.problem(in: "[\\]a-z\\d\\-]+") == nil)
    }

    @Test("A cached pattern is reused only for the same characters, not a canonically equal spelling")
    func regexCacheKey() throws {
        let composed = try A2UIFormatters.expression("^[\u{E9}]$")
        let decomposed = try A2UIFormatters.expression("^[e\u{301}]$")

        #expect(composed !== decomposed)
        #expect(decomposed.firstMatch(in: "e", range: NSRange(location: 0, length: 1)) != nil)
    }

    @Test("A media link follows the basic catalog's URL rules, and a relative path is left to the media resolver")
    func mediaLinks() {
        #expect(A2UIImageView.link("  https://ex.com/my photo.jpg ")?.absoluteString == "https://ex.com/my%20photo.jpg")
        #expect(A2UIImageView.link("data:image/png;base64,AAAA")?.scheme == "data")
        #expect(A2UIImageView.link("/media/clip.mp4")?.absoluteString == "/media/clip.mp4")
        #expect(A2UIImageView.link("AppIcon")?.scheme == nil)
        #expect(A2UIImageView.link("AppIcon").flatMap(A2UIRenderer.webURL) == nil)
        let rejected = [
            "", "https:clip.mp4", "https:///clip.mp4", "//evil.example/a.png", "/\\evil.example/a.png", "/\t/evil.example/a.png",
            "javascript:alert(1)", "file:///etc/hosts"
        ]
        for link in rejected {
            #expect(A2UIImageView.link(link) == nil, "\(link)")
        }
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
