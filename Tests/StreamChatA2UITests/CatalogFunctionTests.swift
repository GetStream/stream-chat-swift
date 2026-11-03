//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import Testing

/// Invokes a basic catalog function with literal arguments.
@MainActor
private func invoke(
    _ definition: FunctionDefinition,
    _ arguments: JsonMap,
    data: JsonMap = [:],
    services: RendererServices = TestServices.make()
) -> (any Sendable)? {
    let (evaluator, model) = makeEvaluator(
        data: data,
        catalogs: [BasicCatalog.catalog],
        surfaceCatalogId: BasicCatalog.catalogId,
        services: services
    )
    let context = DataContext(model, "/")
    let resolved = evaluator.resolveArguments(arguments, in: context)
    return evaluator.execute(definition, arguments: resolved, in: context)
}

/// Invokes a function and reads the validation result it produced.
@MainActor
private func validate(_ definition: FunctionDefinition, _ arguments: JsonMap, data: JsonMap = [:]) -> ValidationResult {
    ValidationResult(coercing: invoke(definition, arguments, data: data))
}

@MainActor
@Suite("Validation functions")
struct ValidationFunctionTests {
    @Test("required rejects empty values, and only those")
    func required() {
        #expect(!validate(ValidationFunctions.required, ["value": ""]).isValid)
        #expect(validate(ValidationFunctions.required, ["value": "   "]).isValid)
        #expect(!validate(ValidationFunctions.required, ["value": [String]()]).isValid)
        #expect(!validate(ValidationFunctions.required, ["value": NSNull()]).isValid)
        #expect(validate(ValidationFunctions.required, ["value": "a"]).isValid)
        #expect(validate(ValidationFunctions.required, ["value": false]).isValid)
        #expect(validate(ValidationFunctions.required, ["value": 0]).isValid)
    }

    @Test("required reads its value through a binding")
    func requiredBinding() {
        #expect(
            !validate(
                ValidationFunctions.required,
                ["value": ["@path": "/order/items"]],
                data: ["order": ["items": [String]()] as JsonMap]
            ).isValid
        )
        #expect(
            validate(
                ValidationFunctions.required,
                ["value": ["@path": "/order/items"]],
                data: ["order": ["items": ["tea"]] as JsonMap]
            ).isValid
        )
    }

    @Test("regex matches the pattern and passes empty values")
    func regex() {
        #expect(validate(ValidationFunctions.regex, ["value": "1234567890", "pattern": "^\\d{10}$"]).isValid)
        #expect(!validate(ValidationFunctions.regex, ["value": "12345", "pattern": "^\\d{10}$"]).isValid)
        #expect(validate(ValidationFunctions.regex, ["value": "", "pattern": "^\\d{10}$"]).isValid)
    }

    @Test("An invalid pattern is reported as a function failure")
    func invalidRegex() {
        #expect(invoke(ValidationFunctions.regex, ["value": "a", "pattern": "["]) == nil)
    }

    @Test("length checks both bounds")
    func length() {
        #expect(validate(ValidationFunctions.length, ["value": "abc", "min": 2, "max": 4]).isValid)
        #expect(!validate(ValidationFunctions.length, ["value": "a", "min": 2]).isValid)
        #expect(!validate(ValidationFunctions.length, ["value": "abcde", "max": 4]).isValid)
        #expect(validate(ValidationFunctions.length, ["value": "abc", "min": 2]).code == nil)
    }

    @Test("numeric checks both bounds and rejects non-numbers")
    func numeric() {
        #expect(validate(ValidationFunctions.numeric, ["value": 5, "min": 1, "max": 10]).isValid)
        #expect(!validate(ValidationFunctions.numeric, ["value": 0, "min": 1]).isValid)
        #expect(!validate(ValidationFunctions.numeric, ["value": 11, "max": 10]).isValid)
        #expect(!validate(ValidationFunctions.numeric, ["value": "abc", "min": 1]).isValid)
        #expect(validate(ValidationFunctions.numeric, ["value": NSNull(), "min": 1]).isValid)
    }

    @Test("email accepts addresses and passes empty values")
    func email() {
        #expect(validate(ValidationFunctions.email, ["value": "ada@example.com"]).isValid)
        #expect(!validate(ValidationFunctions.email, ["value": "ada@example"]).isValid)
        #expect(!validate(ValidationFunctions.email, ["value": "ada"]).isValid)
        #expect(validate(ValidationFunctions.email, ["value": ""]).isValid)
    }
}

@MainActor
@Suite("Format functions")
struct FormatFunctionTests {
    @Test("formatNumber applies grouping and precision")
    func formatNumber() {
        #expect(Json.string(invoke(FormatFunctions.formatNumber, ["value": 1234.5])) == "1,234.5")
        #expect(Json.string(invoke(FormatFunctions.formatNumber, ["value": 1234.5, "grouping": false])) == "1234.5")
        #expect(Json.string(invoke(FormatFunctions.formatNumber, ["value": 1234.5, "decimals": 2])) == "1,234.50")
    }

    @Test("formatCurrency uses the ISO code")
    func formatCurrency() {
        #expect(Json.string(invoke(FormatFunctions.formatCurrency, ["value": 12.5, "currency": "USD"])) == "$12.50")
        #expect(
            Json.string(invoke(FormatFunctions.formatCurrency, ["value": 12, "currency": "EUR", "decimals": 0])) == "€12"
        )
    }

    @Test("formatDate applies a TR35 pattern")
    func formatDate() {
        #expect(
            Json.string(
                invoke(FormatFunctions.formatDate, ["value": "2026-01-16T14:30:00Z", "format": "MMM dd, yyyy"])
            ) == "Jan 16, 2026"
        )
        #expect(
            Json.string(invoke(FormatFunctions.formatDate, ["value": "2026-01-16T14:30:00Z", "format": "HH:mm"]))
                == "14:30"
        )
        #expect(
            Json.string(invoke(FormatFunctions.formatDate, ["value": "2026-01-16", "format": "EEEE"])) == "Friday"
        )
    }

    @Test("formatDate accepts epoch timestamps and rejects nonsense")
    func formatDateInputs() {
        #expect(
            Json.string(invoke(FormatFunctions.formatDate, ["value": 1_767_225_600, "format": "yyyy"])) == "2026"
        )
        #expect(
            Json.string(invoke(FormatFunctions.formatDate, ["value": 1_767_225_600_000, "format": "yyyy"])) == "2026"
        )
        #expect(Json.string(invoke(FormatFunctions.formatDate, ["value": "yesterday", "format": "yyyy"])) == "")
    }

    @Test("pluralize picks a category with an 'other' fallback")
    func pluralize() {
        let arguments: JsonMap = ["one": "1 review", "other": "many reviews", "zero": "no reviews"]
        #expect(Json.string(invoke(FormatFunctions.pluralize, arguments.merging(["value": 1]) { _, new in new })) == "1 review")
        #expect(Json.string(invoke(FormatFunctions.pluralize, arguments.merging(["value": 0]) { _, new in new })) == "no reviews")
        #expect(Json.string(invoke(FormatFunctions.pluralize, arguments.merging(["value": 7]) { _, new in new })) == "many reviews")
        #expect(Json.string(invoke(FormatFunctions.pluralize, ["value": 0, "other": "n items"])) == "n items")
    }

    @Test("formatString interpolates through the evaluator")
    func formatString() {
        let (evaluator, model) = makeEvaluator(
            data: ["name": "Ada"],
            catalogs: [BasicCatalog.catalog],
            surfaceCatalogId: BasicCatalog.catalogId
        )
        let value = evaluator.invoke(
            FunctionCall(name: "formatString", arguments: ["value": "Hi ${/name}"]),
            in: DataContext(model, "/")
        )

        #expect(Json.string(value) == "Hi Ada")
    }
}

@MainActor
@Suite("Logic functions")
struct LogicFunctionTests {
    @Test("and requires every value to be truthy")
    func and() {
        #expect(Json.bool(invoke(LogicFunctions.and, ["values": [true, true]])) == true)
        #expect(Json.bool(invoke(LogicFunctions.and, ["values": [true, false]])) == false)
    }

    @Test("or requires one truthy value")
    func or() {
        #expect(Json.bool(invoke(LogicFunctions.or, ["values": [false, true]])) == true)
        #expect(Json.bool(invoke(LogicFunctions.or, ["values": [false, false]])) == false)
    }

    @Test("not negates its value")
    func not() {
        #expect(Json.bool(invoke(LogicFunctions.not, ["value": false])) == true)
        #expect(Json.bool(invoke(LogicFunctions.not, ["value": true])) == false)
    }

    @Test("Validation results compose with the logical functions")
    func validationResultComposition() {
        let valid = ValidationResult.valid.rawValue
        let invalid = ValidationResult.invalid("nope").rawValue

        #expect(Json.bool(invoke(LogicFunctions.and, ["values": [valid, valid]])) == true)
        #expect(Json.bool(invoke(LogicFunctions.and, ["values": [valid, invalid]])) == false)
        #expect(LogicFunctions.truthy(invalid) == false)
        #expect(LogicFunctions.truthy("text") == true)
        #expect(LogicFunctions.truthy(nil) == false)
    }
}

@MainActor
@Suite("Action functions")
struct ActionFunctionTests {
    @Test("openUrl opens allowed schemes")
    func openUrl() {
        let opened = OpenedUrls()
        _ = invoke(
            ActionFunctions.openUrl,
            ["url": "https://example.com/menu"],
            services: TestServices.make(openedUrls: opened)
        )

        #expect(opened.urls.map(\.absoluteString) == ["https://example.com/menu"])
    }

    @Test("openUrl refuses schemes outside the allow list")
    func rejectedSchemes() {
        let opened = OpenedUrls()
        for url in ["javascript:alert(1)", "file:///etc/passwd", "myapp://danger"] {
            _ = invoke(ActionFunctions.openUrl, ["url": url], services: TestServices.make(openedUrls: opened))
        }

        #expect(opened.urls.isEmpty)
    }

    @Test("openUrl requires user activation, so only the renderer may call it")
    func userActivation() {
        #expect(ActionFunctions.openUrl.requiresUserActivation)
        #expect(ActionFunctions.openUrl.allowedCallers == .rendererOnly)
        #expect(!ActionFunctions.openUrl.isAgentCallable)
    }
}
