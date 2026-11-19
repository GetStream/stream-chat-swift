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

private func regexRejection(_ pattern: String) -> A2UIRegex.Rejection.Code? {
    do {
        _ = try A2UIRegex.icuPattern(for: pattern)
        return nil
    } catch {
        return (error as? A2UIRegex.Rejection)?.code
    }
}

@MainActor
private func regexMatches(_ pattern: String, _ value: String) -> Bool {
    ValidationResult(coercing: callFunction(ValidationFunctions.regex, ["value": value, "pattern": pattern])).isValid
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

        let smallest = A2UISliderView.range(minimum: 0, maximum: 1e-15)
        let smallestStep = A2UISliderView.step(in: smallest, steps: 4)
        #expect(A2UISliderView.rounded(2.5e-16, in: smallest, step: smallestStep) == 2.5e-16)
        #expect(A2UISliderView.rounded(2.6e-16, in: smallest, step: smallestStep) == 2.5e-16)
    }

    @Test("A slider over a large range keeps the fraction of its lower bound")
    func sliderOverALargeRange() {
        let range = A2UISliderView.range(minimum: 1_000_000_000.25, maximum: 1_000_000_004.25)
        let step = A2UISliderView.step(in: range, steps: 4)

        #expect(A2UISliderView.rounded(1_000_000_001.25, in: range, step: step) == 1_000_000_001.25)
        #expect(A2UISliderView.rounded(1_000_000_001.4, in: range, step: step) == 1_000_000_001.25)
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
            showsDate: true,
            showsTime: false
        )
        let lower = try #require(range.lower)
        let shown = A2UIDateTimeInputView.shown(TestServices.referenceDate, in: range)
        let written = A2UIDateTimeInputView.format(shown, showsDate: true, showsTime: false, timeZone: utc)

        #expect(written == "2026-04-01")
        #expect(try #require(A2UIDateParser.date(from: written, timeZone: utc)) >= lower)
        #expect(range.upper == A2UIDateParser.date(from: "2026-04-03", timeZone: utc))

        let withTime = A2UIDateTimeInputView.range(
            minimum: "2026-04-01T12:00:00Z",
            maximum: nil,
            timeZone: utc,
            showsDate: true,
            showsTime: true
        )
        #expect(withTime.lower == A2UIDateParser.date(from: "2026-04-01T12:00:00Z", timeZone: utc))
    }

    @Test("A time-only input reads offset times and compares its bounds by the time they show")
    func timeOnlyBoundsWithOffsetsAndDays() throws {
        let utc = TimeZone(secondsFromGMT: 0) ?? .current
        let nineAM = try #require(A2UIDateParser.date(from: "09:00:00", timeZone: utc))
        let fivePM = try #require(A2UIDateParser.date(from: "17:00:00", timeZone: utc))

        #expect(A2UIDateParser.date(from: "09:00:00Z", timeZone: utc) == nineAM)
        #expect(A2UIDateParser.date(from: "11:00:00+02:00", timeZone: utc) == nineAM)
        #expect(A2UIDateParser.date(from: "04:00:00-05:00", timeZone: utc) == nineAM)
        #expect(A2UIDateParser.date(from: "09:00:00.000Z", timeZone: utc) == nineAM)
        let offset = A2UIDateTimeInputView.range(minimum: "09:00:00Z", maximum: "17:00:00Z", timeZone: utc, showsDate: false, showsTime: true)
        #expect(offset.lower == nineAM)
        #expect(offset.upper == fivePM)

        let days = A2UIDateTimeInputView.range(
            minimum: "2026-01-16T09:00:00Z",
            maximum: "2026-01-16T17:00:00Z",
            timeZone: utc,
            showsDate: false,
            showsTime: true
        )
        #expect(days.lower == nineAM)
        #expect(days.upper == fivePM)
        let now = try #require(A2UIDateParser.clockTime(of: TestServices.referenceDate, timeZone: utc))
        let shown = A2UIDateTimeInputView.shown(now, in: days)
        let written = A2UIDateTimeInputView.format(shown, showsDate: false, showsTime: true, timeZone: utc)
        let read = try #require(A2UIDateParser.date(from: written, timeZone: utc))
        #expect(written == "09:00:00")
        #expect(read >= nineAM && read <= fivePM)
    }

    @Test("formatDate shows a time with an offset in the zone it was written in")
    func formatOffsetTime() {
        let formatted = callFunction(FormatFunctions.formatDate, ["value": "09:30:00+02:00", "format": "HH:mm"])

        #expect(Json.string(formatted) == "09:30")
    }

    @Test("test_evaluate_function_format_date_iso_utc: ISO dates are written in UTC")
    func isoInUTC() {
        let formatted = callFunction(FormatFunctions.formatDate, ["value": "2026-09-04T23:30:00-05:00", "format": "ISO"])

        #expect(Json.string(formatted) == "2026-09-05T04:30:00.000Z")
    }

    @Test("regex safety rule 2: a quantifier above 1 can't repeat a part that repeats without bound")
    func regexNestedQuantifiers() {
        for pattern in ["^([a-zA-Z0-9]+\\s?)*$", "(?:x*){2}", "(a|b+)+", "((?:a+))+", "(\\d+){2,}", "(?:(?=a+)b)*"] {
            #expect(regexRejection(pattern) == .nestedQuantifier, "\(pattern)")
        }
        for pattern in ["^\\d{10}$", "^\\+?[0-9]{10,15}$", "^(a|b)?c$", "(a+){0,1}", "(\\d{1,3}){1,4}", "(a{1,2})+"] {
            #expect(regexRejection(pattern) == nil, "\(pattern)")
        }
    }

    @Test("regex safety rule 3: an unbounded quantifier can't repeat a choice whose options start alike")
    func regexOverlappingAlternation() {
        for pattern in ["(a|ab)+", "(\\w|\\d)+", "([a-m]|[g-z])*", "(?:(a)|a?b)*", "(x|y|.)*"] {
            #expect(regexRejection(pattern) == .overlappingAlternation, "\(pattern)")
        }
        for pattern in ["(cat|dog)+", "(a|ab)", "(a|ab)?", "(a|ab){1,3}", "(\\d|[a-f])+", "(|a)*"] {
            #expect(regexRejection(pattern) == nil, "\(pattern)")
        }
    }

    @Test("regex safety rule 4: parts that repeat without bound and match the same characters can't be adjacent")
    func regexAdjacentOverlap() {
        for pattern in [".*.*", "\\w+\\d+", "a+a+", "(\\d+)(\\d+)", "\\d+\\b\\d+", "\\d+(?=x)\\d*", "a*b?a+", "[^x]+\\s*y*\\d+"] {
            #expect(regexRejection(pattern) == .adjacentOverlap, "\(pattern)")
        }
        for pattern in ["^\\d+-\\d+$", "\\d+[a-z]+\\d+", "\\d{1,3}\\d+", "a*b*c*", "\\d+(?:x\\d+)"] {
            #expect(regexRejection(pattern) == nil, "\(pattern)")
        }
    }

    @Test("regex reports the rules in order, and the length before the syntax")
    func regexRuleOrder() {
        #expect(regexRejection("\\d+\\d+(a+)+") == .nestedQuantifier)
        #expect(regexRejection("\\d+\\d+(a|ab)*") == .overlappingAlternation)
        #expect(regexRejection("(" + String(repeating: "a", count: 256)) == .patternTooLong)
        #expect(regexRejection(String(repeating: "\u{1F600}", count: 256)) == nil)
        #expect(regexRejection(String(repeating: "\u{1F600}", count: 257)) == .patternTooLong)
    }

    @Test("regex translates the dialect's classes, anchors and escapes onto ICU")
    func regexDialect() {
        #expect(!regexMatches("^[\\d]+$", "\u{663}"))
        #expect(!regexMatches("^[\\w]+$", "\u{E9}"))
        #expect(regexMatches("^[^\\W]+$", "Word_42"))
        #expect(regexMatches("^\\s+$", "\u{0B}\u{FEFF}\u{2029}\u{3000}"))
        #expect(!regexMatches("^\\s$", "\u{85}"))
        #expect(regexMatches("^.$", "\u{0B}"))
        #expect(regexMatches("^.$", "\u{85}"))
        #expect(!regexMatches("^.$", "\r"))
        #expect(!regexMatches("^.$", "\u{2028}"))
        #expect(regexMatches("\\Bb", "ab"))
        #expect(!regexMatches("\\Bb", "\u{E9}b"))
        #expect(regexMatches("\\bcat\\b", "\u{E9}cat"))
        #expect(!regexMatches("^a$", "a\n"))
        #expect(regexMatches("^\\uD83D\\uDE00$", "\u{1F600}"))
        #expect(regexMatches("^\\u{00000041}\\x42\\u0043$", "ABC"))
        #expect(regexMatches("^[\\u{1F600}-\\u{1F64F}]$", "\u{1F642}"))
        #expect(regexMatches("^[\\b]$", "\u{08}"))
        #expect(regexMatches("^\\/\\$\\{\\}$", "/${}"))
        #expect(regexMatches("^[a-]+$", "a-a"))
        #expect(regexMatches("^a+?b??c{2}?$", "acc"))
        #expect(regexMatches("", "anything"))
        #expect(!regexMatches("[^\\s\\S]", "anything"))
    }

    @Test("regex rejects what the dialect leaves out or doesn't parse")
    func regexUnsupportedSyntax() {
        let patterns = [
            "\\k<n>", "(?<!a)b", "(?i:a)", "(?>a)", "\\P{L}", "\\cA", "\\A", "\\z", "\\a", "\\-", "\\uD800", "\\u{D800}",
            "\\u{110000}", "\\u{}", "\\x4", "\\", "a**", "a++", "a{2}{3}", "^*", "(?=a)+", "\\b+", "{2}", "a{", "a{x}", "a{,3}",
            "a{5,3}", "a{65536}", "a{1,65536}", "a{99999999999999999999}", "}", "]", "(a", "a)", "[a", "[]", "[^]", "[z-a]", "[\\d-z]",
            "[a-\\w]", "[a--b]", "[a&&b]", "[[:alpha:]]", "[\\B]"
        ]
        for pattern in patterns {
            #expect(regexRejection(pattern) == .unsupportedSyntax, "\(pattern)")
        }
        #expect(regexRejection("a{65535}") == nil)
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

        #expect(router.errors.map(\.message) == ["PATTERN_TOO_LONG: regex can't use its pattern: it is longer than 256 code points."])
    }

    @Test("A rejected pattern's error starts with the specification's code")
    func regexErrorCodes() {
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(catalogs: [BasicCatalog.catalog], surfaceCatalogId: BasicCatalog.catalogId, router: router)
        let context = DataContext(model, "/")

        _ = evaluator.execute(ValidationFunctions.regex, arguments: ["value": "12", "pattern": "\\d+\\d+"], in: context)
        _ = evaluator.execute(ValidationFunctions.regex, arguments: ["value": "a", "pattern": "(?<n>a)"], in: context)

        #expect(router.errors.map(\.code) == [RendererError.Code.expressionError, RendererError.Code.expressionError])
        #expect(router.errors.first?.message.hasPrefix("ADJACENT_OVERLAP: regex can't use '\\d+\\d+': two parts") == true)
        #expect(router.errors.last?.message == "UNSUPPORTED_SYNTAX: regex can't use '(?<n>a)': named groups aren't allowed.")
    }

    @Test("A character class can't hold an escape the regex dialect leaves out")
    func regexEscapesInClasses() {
        #expect(regexRejection("[\\p{L}]") == .unsupportedSyntax)
        #expect(regexRejection("[\\1]") == .unsupportedSyntax)
        #expect(regexRejection("[\\]a-z\\d\\-]+") == nil)
    }

    @Test("A legacy octal escape isn't allowed, while \\0 alone is the null character")
    func regexOctalEscapes() {
        #expect(regexRejection("^\\0141$") == .unsupportedSyntax)
        #expect(regexRejection("[\\01]") == .unsupportedSyntax)
        #expect(regexRejection("^a\\0$") == nil)
        #expect(regexRejection("[\\0a]") == nil)
    }

    @Test("A cached pattern is reused only for the same characters, not a canonically equal spelling")
    func regexCacheKey() throws {
        let composed = try A2UIFormatters.expression("^[\u{E9}]$")
        let decomposed = try A2UIFormatters.expression("^[e\u{301}]$")

        #expect(composed !== decomposed)
        #expect(decomposed.firstMatch(in: "e", range: NSRange(location: 0, length: 1)) != nil)
        #expect(try A2UIFormatters.dialectExpression("^[\u{E9}]$") !== A2UIFormatters.dialectExpression("^[e\u{301}]$"))
        #expect(regexMatches("^[e\u{301}]$", "e"))
    }

    @Test("A media link follows the basic catalog's URL rules, and a relative path is left to the media resolver")
    func mediaLinks() {
        #expect(A2UIImageView.link("  https://ex.com/my photo.jpg ")?.absoluteString == "https://ex.com/my%20photo.jpg")
        #expect(A2UIImageView.link("data:image/png;base64,AAAA")?.scheme == "data")
        #expect(A2UIImageView.link(" data:image/png;base64,AA\nAA ")?.absoluteString == "data:image/png;base64,AAAA")
        #expect(A2UIImageView.link("DATA:text/plain,a")?.scheme?.lowercased() == "data")
        #expect(A2UIImageView.link("da\tta:text/plain,a b")?.absoluteString == "data:text/plain,a%20b")
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
