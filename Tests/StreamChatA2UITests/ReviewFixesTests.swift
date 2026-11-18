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
@Suite("Bounded work on untrusted messages")
struct BoundedWorkTests {
    @Test("A template that formats itself many times on each level stops early")
    func selfFormattingTemplateFanOut() throws {
        let part = "${formatString(value:${/t})}"
        let template = String(repeating: part, count: 300)
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(data: ["t": template], router: router)
        let started = ProcessInfo.processInfo.systemUptime

        _ = try evaluator.interpolate(template, in: DataContext(model, "/"))

        #expect(ProcessInfo.processInfo.systemUptime - started < 2)
        #expect(router.errors.allSatisfy { $0.code == RendererError.Code.expressionError })
    }

    @Test("A size cut short by a cycle isn't reused where the component renders in full")
    func cycleDoesNotHideExpansion() {
        let renderer = makeRenderer([
            Component(id: "root", type: "Column", properties: ["children": ["a", "b"]]),
            Component(id: "a", type: "Column", properties: ["children": ["b"] + Array(repeating: "c", count: 100)]),
            Component(id: "b", type: "Column", properties: ["children": Array(repeating: "a", count: 100)]),
            Component(id: "c", type: "Text", properties: ["text": "c"])
        ])

        #expect(renderer.renderer.expandedSize(limit: 5000, dataContext: DataContext(renderer.model, "/")) > 5000)
    }

    @Test("A template counts its child once for each item")
    func templatesCountEachItem() {
        let items = Array(repeating: ["x": 1] as JsonMap, count: 100) as JsonArray
        let list = makeRenderer(
            [
                Component(id: "root", type: "Column", properties: ["children": ["componentId": "a", "path": "/items"] as JsonMap]),
                Component(id: "a", type: "Text", properties: ["text": "a"])
            ],
            data: ["items": items]
        )
        #expect(list.renderer.expandedSize(limit: 5000, dataContext: DataContext(list.model, "/")) == 101)

        let nested = makeRenderer(
            [
                Component(id: "root", type: "Column", properties: ["children": ["componentId": "a", "path": "/items"] as JsonMap]),
                Component(id: "a", type: "Column", properties: ["children": ["componentId": "b", "path": "/items"] as JsonMap]),
                Component(id: "b", type: "Text", properties: ["text": "b"])
            ],
            data: ["items": items]
        )
        #expect(nested.renderer.expandedSize(limit: 5000, dataContext: DataContext(nested.model, "/")) > 5000)
    }

    private func makeRenderer(_ components: [Component], data: JsonMap = [:]) -> (renderer: SurfaceRenderer, model: DataModel) {
        var definition = SurfaceDefinition(surfaceId: "surface", catalogId: TestCatalog.catalogId)
        definition.merge(components)
        let (evaluator, model) = makeEvaluator(data: data)
        let renderer = SurfaceRenderer(definition: definition, catalogs: evaluator.catalogs, evaluator: evaluator, onAction: { _ in })
        return (renderer, model)
    }
}

@MainActor
@Suite("Component envelope and malformed components")
struct ComponentEnvelopeTests {
    @Test("The spec's @ envelope keys are read, ahead of the unprefixed ones")
    func prefixedEnvelopeKeys() throws {
        let component = try #require(Component.fromJson([
            "id": "email",
            "component": "TextField",
            "@checks": [["condition": true, "message": "x"] as JsonMap] as JsonArray,
            "@accessibility": ["label": "Work email"] as JsonMap,
            "@catalogId": "other",
            "catalogId": "ignored",
            "@metadata": ["extensions": [:] as JsonMap] as JsonMap
        ]))

        #expect(component.checks.count == 1)
        #expect(component.catalogId == "other")
        #expect(component.accessibility?.label.rawValue as? String == "Work email")
        #expect(component.metadata != nil)
        #expect(component.properties.keys.allSatisfy { !$0.hasPrefix("@") && $0 != "catalogId" })
    }

    @Test("A component without an id or type is reported, and errors point at the entry in the message")
    func malformedComponents() throws {
        let harness = ProcessorHarness()
        let message = try decodeMessage("""
        {"version": "1.0", "createSurface": {"surfaceId": "main", "catalogId": "\(TestCatalog.catalogId)", "components": [
            {"id": "title", "type": "Text"},
            "nope",
            {"id": "b", "component": "Buton"}
        ]}}
        """)
        harness.processor.handle(message)

        #expect(harness.errors.map(\.path) == ["/components/0/component", "/components/1", "/components/2/component"])
        #expect(harness.errors.allSatisfy { $0.code == RendererError.Code.validationFailed })
    }
}

@MainActor
@Suite("Agent function failures")
struct AgentFunctionFailureTests {
    @Test("test_agent_routing_agent_error_is_expression_error: an error answer is reported with its call")
    func errorAnswer() throws {
        let harness = ProcessorHarness()
        harness.createSurface()
        _ = try harness.processor.agentFunctionValue(for: "fetchFxRate", catalogId: nil, arguments: [:], surfaceId: "main")
        let call = try #require(harness.agentCalls.first)

        harness.processor.handle(.agentFunctionResponse(FunctionResponse(
            functionCallId: call.functionCallId,
            error: FunctionResponse.Failure(code: "UNKNOWN_FUNCTION", message: "No such function: fetchFxRate")
        )))

        let error = try #require(harness.errors.first)
        #expect(error.code == RendererError.Code.expressionError)
        #expect(error.message == "No such function: fetchFxRate")
        #expect(error.functionCallId == call.functionCallId)
        #expect(error.surfaceId == nil)
    }

    @Test("A call the agent doesn't answer in time is reported")
    func timeout() async throws {
        let harness = ProcessorHarness(agentFunctionTimeout: 0.01)
        harness.createSurface()
        _ = try harness.processor.agentFunctionValue(for: "estimate", catalogId: nil, arguments: [:], surfaceId: "main")
        let call = try #require(harness.agentCalls.first)

        await waitUntil("the timeout's report") { !harness.errors.isEmpty }

        #expect(harness.errors.map(\.code) == [RendererError.Code.expressionError])
        #expect(harness.errors.first?.functionCallId == call.functionCallId)
    }

    @Test("A surface created again reports the problems its earlier one reported")
    func dedupeIsPerSurface() {
        let harness = ProcessorHarness()
        let unknown = [Component(id: "root", type: "Nope")]
        harness.createSurface(components: unknown)
        harness.processor.handle(.deleteSurface(DeleteSurfaceMessage(surfaceId: "main")))
        harness.createSurface(components: unknown)

        #expect(harness.errors.map(\.code) == [RendererError.Code.validationFailed, RendererError.Code.validationFailed])
    }
}

@Suite("Incremental stream scanning")
struct StreamScannerTests {
    @Test("Scanning a reply chunk by chunk finds what one scan of it does")
    func chunks() {
        let text = #"{"version":"1.0","createSurface":{"surfaceId":"a"}} {"text":"a } \" { b"} {"open":"#
        var scanner = A2UIStreamScanner()
        var source = ""
        for character in text {
            source.append(character)
            let carriesOn = scanner.scan(source)
            #expect(carriesOn)
        }

        #expect(scanner.messages == A2UIStream.messages(in: text))
        #expect(scanner.messages.count == 2)
        #expect(scanner.hasOpenMessage)
    }

    @Test("Text that doesn't carry on from the last is scanned again")
    func rewrite() {
        var scanner = A2UIStreamScanner()
        scanner.scan(#"{"a":1} {"b":2}"#)

        let carriesOn = scanner.scan(#"{"c":3}"#)
        #expect(!carriesOn)
        #expect(scanner.messages == [#"{"c":3}"#])
        #expect(!scanner.hasOpenMessage)
    }
}

@MainActor
@Suite("Catalog fixes")
struct CatalogFixesTests {
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
