//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import Testing

/// Cases from the A2UI conformance suite (`conformance/core` in
/// github.com/a2ui-project/a2ui), named after the case they reproduce.
@MainActor
@Suite("Data model pointers and deletion")
struct DataModelConformanceTests {
    private func model(_ initial: JsonMap) -> DataModel {
        DataModel(initial)
    }

    @Test("test_pointer_escape_characters")
    func escapeCharacters() throws {
        let model = model(["a/b": ["c~d": "original_value"] as JsonMap, "slash/key": 100])
        try model.set("escaped_value", at: DataPath("/a~1b/c~0d"))

        #expect(Json.isEqual(model.snapshot, ["a/b": ["c~d": "escaped_value"] as JsonMap, "slash/key": 100] as JsonMap))
    }

    @Test("test_pointer_extended_escape_sequences")
    func extendedEscapes() throws {
        let model = model(["m~0": "val0", "m/1": "val1", "m~1": "val2", "m/0": "val3"])
        try model.set("updated0", at: DataPath("/m~00"))
        try model.set("updated1", at: DataPath("/m~11"))
        try model.set("updated2", at: DataPath("/m~01"))
        try model.set("updated3", at: DataPath("/m~10"))

        #expect(Json.isEqual(model.snapshot, ["m~0": "updated0", "m/1": "updated1", "m~1": "updated2", "m/0": "updated3"] as JsonMap))
    }

    @Test("test_pointer_array_indexing and appending")
    func arrayIndexing() throws {
        let model = model(["items": ["first", "second", "third"]])
        try model.set("updated_second", at: DataPath("/items/1"))
        try model.set("fourth", at: DataPath("/items/3"))
        try model.set("fifth", at: DataPath("/items/-"))

        #expect(Json.stringArray(model.value(at: DataPath("/items"))) == ["first", "updated_second", "third", "fourth", "fifth"])
    }

    @Test("test_pointer_auto_vivification")
    func autoVivification() throws {
        let model = model([:])
        try model.set("vivified_value", at: DataPath("/deeply/nested/structure/key"))
        try model.set("x", at: DataPath("/list/0/name"))

        #expect(model.string(at: DataPath("/deeply/nested/structure/key")) == "vivified_value")
        #expect(Json.array(model.value(at: DataPath("/list")))?.count == 1)
    }

    @Test("test_pointer_reject_leading_zero_array_index, _non_numeric_array_segment, out of bounds")
    func invalidIndices() {
        let model = model(["items": ["a", "b", "c"]])
        for path in ["/items/01", "/items/invalidKey", "/items/-1", "/items/10001"] {
            #expect(throws: DataModelError.self) { try model.set("x", at: DataPath(path)) }
        }
        #expect(Json.stringArray(model.value(at: DataPath("/items"))) == ["a", "b", "c"])
    }

    @Test("test_pointer_reject_write_through_primitive")
    func writeThroughPrimitive() {
        let model = model(["user": "Alice"])
        #expect(throws: DataModelError.notAContainer(DataPath("/user/name/first"))) {
            try model.set("Alice", at: DataPath("/user/name/first"))
        }
        #expect(model.string(at: DataPath("/user")) == "Alice")
    }

    @Test("test_data_deletion_value_null and sibling preservation")
    func deleteValue() throws {
        let model = model(["settings": ["notifications": ["email": true, "push": false] as JsonMap, "theme": "dark"] as JsonMap])
        try model.set(nil, at: DataPath("/settings/notifications/email"))
        #expect(Json.isEqual(model.value(at: DataPath("/settings/notifications")), ["push": false] as JsonMap))

        try model.set(NSNull(), at: DataPath("/settings/notifications"))
        #expect(Json.isEqual(model.snapshot, ["settings": ["theme": "dark"]] as JsonMap))
    }

    @Test("test_data_deletion_array_index_preservation")
    func deleteArrayElement() throws {
        let model = model(["items": ["a", "b", "c"]])
        try model.set(nil, at: DataPath("/items/1"))

        #expect(Json.isEqual(model.value(at: DataPath("/items")), ["a", NSNull(), "c"] as JsonArray))
    }

    @Test("Deleting a missing path creates nothing")
    func deleteMissing() throws {
        let model = model(["user": "Alice"])
        try model.set(nil, at: DataPath("/profile/name"))
        try model.set(nil, at: DataPath("/user/name/x"))

        #expect(Json.isEqual(model.snapshot, ["user": "Alice"] as JsonMap))
    }

    @Test("test_data_deletion_root_replacement, and the root must stay an object")
    func rootReplacement() throws {
        let model = model(["user": ["name": "Alice"] as JsonMap, "count": 42])
        try model.set(nil, at: .root)
        #expect(model.snapshot.isEmpty)

        #expect(throws: DataModelError.invalidRoot) { try model.set("text", at: .root) }
        try model.set(["a": 1], at: DataPath("/"))
        #expect(Json.int(model.value(at: DataPath("/a"))) == 1)
    }

    @Test("Data model errors describe the path")
    func errorDescriptions() {
        #expect(DataModelError.notAContainer(DataPath("/a/b")).description.contains("/a/b"))
        #expect(DataModelError.invalidArrayIndex("x", path: DataPath("/a/x")).description.contains("non-numeric"))
        #expect(!DataModelError.invalidRoot.description.isEmpty)
    }
}

@MainActor
@Suite("JSON safety")
struct JsonSafetyTests {
    @Test("Decoded numbers keep their type, so 1 is not true")
    func decodedNumbers() throws {
        let json = try #require(Json.decodeMap(#"{"one": 1, "zero": 0, "price": 1.0, "flag": true, "list": [1, 0, 2]}"#))

        #expect(Json.stringify(json["one"]) == "1")
        #expect(Json.stringify(json["zero"]) == "0")
        #expect(Json.stringify(json["price"]) == "1")
        #expect(Json.stringify(json["flag"]) == "true")
        #expect(Json.stringArray(json["list"]) == ["1", "0", "2"])
        #expect(json["one"] is Int)
        #expect(json["flag"] is Bool)
    }

    @Test("Values JSON cannot carry are rejected instead of crashing")
    func nonFiniteNumbers() {
        #expect(Json.double("inf") == nil)
        #expect(Json.double("nan") == nil)
        #expect(Json.double(Double.infinity) == nil)
        #expect(Json.int(1e300) == nil)
        #expect(Json.int("9.7") == 9)
        #expect(Json.encode(["value": Double.nan]) == nil)
        #expect(Json.encode(Double.infinity) == nil)
        #expect(Json.encodeToString("text") == "\"text\"")
        #expect(!Json.canonicalString(["value": Double.nan]).isEmpty)
    }

    @Test("Decoding JSON data")
    func decodeData() {
        #expect(Json.decodeMap(Data(#"{"a": [null, "b"]}"#.utf8)) != nil)
        #expect(Json.decode(Data("not json".utf8)) == nil)
        #expect(Json.decode(Data("null".utf8)) is NSNull)
    }

    @Test("An @index offset too large for an integer is ignored instead of crashing")
    func indexOverflow() {
        let (evaluator, model) = makeEvaluator(data: ["items": [1]])
        let scope = DataContext(model, "/").collectionScope(path: DataPath("/items"), index: 0)

        #expect(Json.int(evaluator.invoke(FunctionCall(name: "@index", arguments: ["offset": 1e300]), in: scope)) == 0)
    }

    @Test("Deeply nested formatString expressions are rejected")
    func expressionDepth() throws {
        let deep = String(repeating: "${", count: 150) + "/a" + String(repeating: "}", count: 150)
        #expect(throws: A2UIExpressionError.self) { try A2UIExpressionParser.parseExpression(deep) }
        #expect(try A2UIExpressionParser.parseExpression("upper(value: ${/a})") != nil)

        let (evaluator, model) = makeEvaluator(data: ["a": "x"])
        #expect(throws: A2UIExpressionError.self) { try evaluator.interpolate("before \(deep) after", in: DataContext(model, "/")) }
    }

    @Test("Messages are found after prose with an odd number of quotes")
    func streamAfterQuotes() {
        let text = """
        Here's the "plan:
        {"version":"1.0","createSurface":{"surfaceId":"a"}}
        {"version":"1.0","deleteSurface":{"surfaceId":"
        """
        #expect(A2UIStream.messages(in: text) == [#"{"version":"1.0","createSurface":{"surfaceId":"a"}}"#])
    }

    @Test("Markdown links are shown as text")
    func markdownLinks() {
        let text = A2UIMarkdown.inline("Read [the docs](https://example.com) **now**")

        #expect(String(text.characters) == "Read the docs now")
        #expect(text.runs.allSatisfy { $0.link == nil })
    }
}

@MainActor
@Suite("Functions and checks")
struct FunctionConformanceTests {
    private func run(_ definition: FunctionDefinition, _ arguments: JsonMap, data: JsonMap = [:]) -> (any Sendable)? {
        let (evaluator, model) = makeEvaluator(
            data: data,
            catalogs: [BasicCatalog.catalog],
            surfaceCatalogId: BasicCatalog.catalogId
        )
        let context = DataContext(model, "/")
        return evaluator.execute(definition, arguments: evaluator.resolveArguments(arguments, in: context), in: context)
    }

    private func isValid(_ definition: FunctionDefinition, _ arguments: JsonMap) -> Bool {
        ValidationResult(coercing: run(definition, arguments)).isValid
    }

    @Test("test_evaluate_function_required_*")
    func required() {
        #expect(isValid(ValidationFunctions.required, ["value": [String: String]()]))
        #expect(isValid(ValidationFunctions.required, ["value": [1, 2]]))
        #expect(!isValid(ValidationFunctions.required, ["value": [Int]()]))
        #expect(!isValid(ValidationFunctions.required, ["value": ""]))
    }

    @Test("test_evaluate_function_length_array_* and email single character TLD")
    func lengthAndEmail() {
        #expect(isValid(ValidationFunctions.length, ["value": ["a", "b", "c"], "min": 2, "max": 4]))
        #expect(!isValid(ValidationFunctions.length, ["value": ["a"], "min": 2]))
        #expect(!isValid(ValidationFunctions.email, ["value": "test@test.c"]))
        #expect(isValid(ValidationFunctions.email, ["value": "user@mail.example.com"]))
    }

    @Test("test_evaluate_function_and/or_fewer_than_two_values_error")
    func logicNeedsTwoValues() {
        #expect(run(LogicFunctions.and, ["values": [true]]) == nil)
        #expect(run(LogicFunctions.or, ["values": [false]]) == nil)
        #expect(Json.bool(run(LogicFunctions.and, ["values": [1, "non-empty"] as JsonArray])) == true)
        #expect(Json.bool(run(LogicFunctions.and, ["values": [1, ""] as JsonArray])) == false)
    }

    @Test("A validation result read as a boolean argument uses its valid flag")
    func groupingCoercion() {
        let invalid: JsonMap = ["@call": "required", "args": ["value": ""] as JsonMap]
        let valid: JsonMap = ["@call": "required", "args": ["value": "x"] as JsonMap]

        #expect(Json.string(run(FormatFunctions.formatNumber, ["value": 1234, "decimals": 0, "grouping": invalid])) == "1234")
        #expect(Json.string(run(FormatFunctions.formatNumber, ["value": 1234, "decimals": 0, "grouping": valid])) == "1,234")
        #expect(Json.string(run(FormatFunctions.formatNumber, ["value": 1.5, "decimals": 1000])) != nil)
    }

    @Test("test_evaluate_function_format_date_* keep the written zone")
    func formatDate() {
        let cases: [(String, String, String)] = [
            ("2026-09-04T23:30:00Z", "yyyy-MM-dd HH:mm", "2026-09-04 23:30"),
            ("2026-09-04T23:30:00", "yyyy-MM-dd HH:mm", "2026-09-04 23:30"),
            ("2026-09-04T23:30:00-05:00", "yyyy-MM-dd HH:mm", "2026-09-04 23:30"),
            ("2026-08-26T12:00:00Z", "yyyy-MM-dd", "2026-08-26"),
            ("2026-08-26T12:00:00.000Z", "ISO", "2026-08-26T12:00:00.000Z"),
            ("2026-02-30", "yyyy-MM-dd", ""),
            ("2026-13-01", "yyyy-MM-dd", "")
        ]
        for (value, format, expected) in cases {
            #expect(Json.string(run(FormatFunctions.formatDate, ["value": value, "format": format])) == expected, "\(value)")
        }
        #expect(A2UIDateParser.writtenTimeZone(of: "2026-09-04T23:30:00+02:00").secondsFromGMT() == 7200)
    }

    @Test("openUrl only opens web pages, and only from a user gesture")
    func openUrl() {
        let opened = OpenedUrls()
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(
            catalogs: [BasicCatalog.catalog],
            surfaceCatalogId: BasicCatalog.catalogId,
            services: TestServices.make(openedUrls: opened),
            router: router
        )
        let context = DataContext(model, "/")
        let open = { (url: String) in FunctionCall(name: "openUrl", arguments: ["url": url]) }

        _ = evaluator.invoke(open("https://example.com/passive"), in: context)
        #expect(opened.urls.isEmpty)
        #expect(router.errors.map(\.code) == [RendererError.Code.expressionError])

        evaluator.withUserActivation {
            _ = evaluator.invoke(open("https://example.com/tap"), in: context)
            _ = evaluator.invoke(open("mailto:a@b.c"), in: context)
            _ = evaluator.invoke(open("javascript:alert(1)"), in: context)
        }
        #expect(opened.urls.map(\.absoluteString) == ["https://example.com/tap"])
    }

    @Test("Check messages: the check's own, then the function's, then the default")
    func checkMessages() {
        let catalog = TestCatalog.make(recorder: RenderRecorder()).adding(
            functions: [
                FunctionDefinition(name: "expired", description: "Fails with its own message.", returnType: .validationResult) { _ in
                    ValidationResult.invalid("The card has expired.", code: "EXPIRED_CARD").rawValue
                }
            ]
        )
        let (evaluator, model) = makeEvaluator(data: ["email": ""], catalogs: [catalog])
        let context = DataContext(model, "/")
        let required = DynamicValue(["@call": "required", "args": ["value": ["@path": "/email"]] as JsonMap] as JsonMap)
        let expired = DynamicValue(["@call": "expired"])

        let messages = evaluator.failingChecks(
            [
                CheckRule(condition: expired, message: "Card problem."),
                CheckRule(condition: required, message: "We need your email."),
                CheckRule(condition: required)
            ],
            in: context
        ).map(\.message)

        #expect(messages == ["Card problem.", "We need your email.", "This field is required."])
        #expect(evaluator.failingChecks([CheckRule(condition: expired)], in: context).map(\.message) == ["The card has expired."])
    }

    @Test("A check whose function fails is invalid; one waiting on the agent passes")
    func failingAndPendingChecks() {
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(router: router)
        let context = DataContext(model, "/")

        let failing = evaluator.failingChecks([CheckRule(condition: DynamicValue(["@call": "boom"]), message: "Broken.")], in: context)
        #expect(failing.map(\.message) == ["Broken."])

        let pending = evaluator.failingChecks([CheckRule(condition: DynamicValue(["@call": "verifyProvider"]))], in: context)
        #expect(pending.isEmpty)
        #expect(router.calls.map(\.name) == ["verifyProvider"])
    }

    @Test("Default messages exist for the basic validation functions that return none")
    func defaultMessages() {
        for name in ["required", "regex", "length", "numeric"] {
            #expect(ValidationFunctions.defaultMessage(forFunction: name) != nil)
        }
        #expect(ValidationFunctions.defaultMessage(forFunction: "email") == nil)
    }

    @Test("test_validation_result_dynamic_object_return: email reports its own code and message")
    func emailResult() {
        let (evaluator, model) = makeEvaluator(data: ["email": "invalid-email-address"])
        let check = CheckRule(condition: DynamicValue(["@call": "email", "args": ["value": ["@path": "/email"] as JsonMap] as JsonMap] as JsonMap))

        let failures = evaluator.failingChecks([check], in: DataContext(model, "/"))

        #expect(failures == [ValidationResult(
            isValid: false,
            code: "INVALID_EMAIL",
            message: "Please enter a valid email address (e.g. user@example.com).",
            severity: .error
        )])
    }

    @Test("test_validation_result_boolean_fallback: a check's message overrides a function's, a bound result keeps its own")
    func messagePrecedence() {
        let (evaluator, model) = makeEvaluator(data: [
            "age": 15, "email": "nope",
            "bound": ["valid": false, "message": "From the data model."] as JsonMap
        ])
        let context = DataContext(model, "/")
        let numeric = CheckRule(
            condition: DynamicValue(["@call": "numeric", "args": ["value": ["@path": "/age"] as JsonMap, "min": 18] as JsonMap] as JsonMap),
            message: "Must be 18 or older."
        )
        let email = CheckRule(
            condition: DynamicValue(["@call": "email", "args": ["value": ["@path": "/email"] as JsonMap] as JsonMap] as JsonMap),
            message: "Please enter a valid email address."
        )
        let bound = CheckRule(condition: DynamicValue(["@path": "/bound"] as JsonMap), message: "From the check.")
        let unlabeled = CheckRule(condition: DynamicValue(["@call": "numeric", "args": ["value": ["@path": "/age"] as JsonMap, "min": 18] as JsonMap] as JsonMap))

        let messages = evaluator.failingChecks([numeric, email, bound, unlabeled], in: context).map(\.message)

        #expect(messages == ["Must be 18 or older.", "Please enter a valid email address.", "From the data model.", "Enter a number in the allowed range."])
        #expect(evaluator.failingChecks([numeric], in: context).first?.code == nil)
    }
}
