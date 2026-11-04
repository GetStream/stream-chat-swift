//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import Testing

@MainActor
@Suite("Expression evaluation")
struct ExpressionEvaluatorTests {
    @Test("Literals, bindings and calls all evaluate")
    func basics() {
        let (evaluator, model) = makeEvaluator(data: ["name": "Ada", "count": 3])
        let context = DataContext(model, "/")

        #expect(Json.string(evaluator.evaluate(DynamicValue("hi"), in: context)) == "hi")
        #expect(Json.string(evaluator.evaluate(DynamicValue(["@path": "/name"]), in: context)) == "Ada")
        #expect(evaluator.evaluate(.missing, in: context) == nil)
        #expect(Json.int(evaluator.evaluate(DynamicValue(["@path": "/count"]), in: context)) == 3)
        #expect(evaluator.evaluate(DynamicValue(["@path": "/missing"]), in: context) == nil)
    }

    @Test("Coercing accessors follow the type conversion rules")
    func coercion() {
        let (evaluator, model) = makeEvaluator(data: ["count": 3, "flag": true, "tags": ["a", "b"]])
        let context = DataContext(model, "/")

        #expect(evaluator.string(DynamicValue(["@path": "/count"]), in: context) == "3")
        #expect(evaluator.double(DynamicValue(["@path": "/count"]), in: context) == 3)
        #expect(evaluator.bool(DynamicValue(["@path": "/flag"]), in: context) == true)
        #expect(evaluator.stringArray(DynamicValue(["@path": "/tags"]), in: context) == ["a", "b"])
    }

    @Test("Relative bindings resolve inside a collection scope")
    func relativeBindings() {
        let (evaluator, model) = makeEvaluator(data: ["items": [["name": "Tea"], ["name": "Coffee"]]])
        let scope = DataContext(model, "/").collectionScope(path: DataPath("/items"), index: 1)

        #expect(evaluator.string(DynamicValue(["@path": "name"]), in: scope) == "Coffee")
    }

    @Test("Nested call arguments are resolved before the function runs")
    func nestedArguments() {
        let (evaluator, model) = makeEvaluator(data: ["a": 2])
        let context = DataContext(model, "/")
        let call = FunctionCall(
            name: "echo",
            arguments: ["value": ["@call": "echo", "args": ["value": ["@path": "/a"]] as JsonMap] as JsonMap]
        )

        #expect(Json.int(evaluator.invoke(call, in: context)) == 2)
    }

    @Test("Arrays of calls are resolved element by element")
    func arrayArguments() {
        let (evaluator, model) = makeEvaluator(data: ["a": true, "b": false])
        let context = DataContext(model, "/")
        let call = FunctionCall(
            name: "and",
            arguments: ["values": [["@path": "/a"], ["@path": "/b"]]]
        )

        #expect(Json.bool(evaluator.invoke(call, in: context)) == false)
    }

    @Test("Unknown functions are routed to the agent")
    func agentRouting() {
        let router = StubRemoteRouter()
        router.answers["deliveryEstimate"] = "25 min"
        let (evaluator, model) = makeEvaluator(data: ["type": "pickup"], router: router)
        let context = DataContext(model, "/")
        let call = FunctionCall(name: "deliveryEstimate", arguments: ["orderType": ["@path": "/type"]])

        #expect(Json.string(evaluator.invoke(call, in: context)) == "25 min")
        #expect(router.calls.count == 1)
        #expect(router.calls[0].name == "deliveryEstimate")
        #expect(Json.string(router.calls[0].arguments["orderType"]) == "pickup")
    }

    @Test("Agent-only functions cannot be bound to component properties")
    func callBoundary() {
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(router: router)
        let context = DataContext(model, "/")

        #expect(evaluator.invoke(FunctionCall(name: "agentOnly"), in: context) == nil)
        #expect(router.errors.count == 1)
        #expect(router.errors[0].code == RendererError.Code.invalidFunctionCall)
    }

    @Test("A failing function reports an error and evaluates to nil")
    func functionFailure() {
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(router: router)
        let context = DataContext(model, "/")

        #expect(evaluator.invoke(FunctionCall(name: "boom"), in: context) == nil)
        #expect(router.errors.count == 1)
        #expect(router.errors[0].code == RendererError.Code.executionError)
    }

    @Test("test_v10_function_call_naming_unknown_catalog_errors: a call whose catalog doesn't resolve fails")
    func catalogResolution() {
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(surfaceCatalogId: "unknown:catalog", router: router)
        let context = DataContext(model, "/")

        // There is no fallback to another catalog, and nothing is routed to the agent.
        #expect(evaluator.invoke(FunctionCall(name: "echo", arguments: ["value": 1]), in: context) == nil)
        #expect(evaluator.invoke(FunctionCall(name: "echo", catalogId: "missing-catalog"), in: context) == nil)
        #expect(router.calls.isEmpty)
        #expect(router.errors.map(\.code) == [RendererError.Code.catalogNotFound, RendererError.Code.catalogNotFound])
        #expect(router.errors.map(\.message) == ["Catalog not found: unknown:catalog", "Catalog not found: missing-catalog"])
    }

    @Test("The @index system function reads the collection scope")
    func indexFunction() {
        let (evaluator, model) = makeEvaluator(data: ["items": [1, 2, 3]])
        let scope = DataContext(model, "/").collectionScope(path: DataPath("/items"), index: 1)
        let rootScope = DataContext(model, "/")

        #expect(Json.int(evaluator.invoke(FunctionCall(name: "@index"), in: scope)) == 1)
        #expect(
            Json.int(evaluator.invoke(FunctionCall(name: "@index", arguments: ["offset": 1]), in: scope)) == 2
        )
        #expect(evaluator.invoke(FunctionCall(name: "@index"), in: rootScope) == nil)
    }

    @Test("Failing checks carry the rule's fallback message")
    func checks() {
        let (evaluator, model) = makeEvaluator(data: ["form": ["email": ""] as JsonMap])
        let context = DataContext(model, "/")
        let rules = CheckRule.list(
            [
                [
                    "condition": ["@call": "required", "args": ["value": ["@path": "/form/email"]] as JsonMap] as JsonMap,
                    "message": "We need your email."
                ] as JsonMap,
                ["condition": ["@call": "required", "args": ["value": "present"]] as JsonMap] as JsonMap
            ] as JsonArray
        )

        let failures = evaluator.failingChecks(rules, in: context)
        #expect(failures.count == 1)
        #expect(failures[0].message == "We need your email.")
    }

    @Test("Boolean conditions are accepted as checks")
    func booleanChecks() {
        let (evaluator, model) = makeEvaluator(data: ["ok": false])
        let context = DataContext(model, "/")
        let rules = CheckRule.list([["condition": ["@path": "/ok"], "message": "Not ok."] as JsonMap] as JsonArray)

        #expect(evaluator.failingChecks(rules, in: context).count == 1)
    }
}

@MainActor
@Suite("formatString parsing")
struct ExpressionParserTests {
    @Test("Templates split into text and expressions")
    func templates() throws {
        let segments = try A2UIExpressionParser.parseTemplate("Hello ${/user/name}, welcome!")

        #expect(segments == [.text("Hello "), .expression(.path(DataPath("/user/name"))), .text(", welcome!")])
    }

    @Test("test_expr_escaped_marker_between_text: a literal dollar-brace sequence can be escaped")
    func escaping() throws {
        #expect(try A2UIExpressionParser.parseTemplate("before \\${x} after") == [.text("before ${x} after")])
    }

    @Test("test_expr_function_call_mixed_arg_types: calls take named paths, strings and calls")
    func functionCalls() throws {
        let expression = try A2UIExpressionParser.parseExpression("format(value: /amount, suffix: ' USD', fallback: zero())")

        #expect(expression == .call(name: "format", arguments: [
            "value": .path(DataPath("/amount")),
            "suffix": .literal(" USD"),
            "fallback": .call(name: "zero", arguments: [:])
        ]))
    }

    @Test("test_expr_nested_interpolation: nested interpolations and calls parse")
    func nestedCalls() throws {
        #expect(try A2UIExpressionParser.parseExpression("now()") == .call(name: "now", arguments: [:]))
        #expect(try A2UIExpressionParser.parseTemplate("${${'hello'}}") == [.text("hello")])
        #expect(
            try A2UIExpressionParser.parseExpression("upper(value: ${lower(value: 'A')})")
                == .call(name: "upper", arguments: ["value": .call(name: "lower", arguments: ["value": .literal("A")])])
        )
    }

    @Test("System functions and numeric arguments parse")
    func systemFunctions() throws {
        #expect(try A2UIExpressionParser.parseExpression("@index(offset: 1)") == .call(name: "@index", arguments: ["offset": .literal(1)]))
        #expect(throws: A2UIExpressionError.self) { try A2UIExpressionParser.parseExpression("@index") }
        #expect(throws: A2UIExpressionError.self) { try A2UIExpressionParser.parseExpression("@1(x: 1)") }
    }

    @Test("Literals parse like the conformance suite's cases")
    func literals() throws {
        let cases: [(String, A2UITemplateSegment)] = [
            ("${42}", .expression(.literal(42))), // test_expr_integer_literal
            ("${-3.14}", .expression(.literal(-3.14))), // test_expr_negative_decimal_literal
            ("${1.5e-3}", .expression(.literal(0.0015))), // test_expr_exponential_notation_negative_exponent
            ("${007}", .expression(.literal(7))), // test_expr_leading_zeros
            ("${1.}", .expression(.literal(1))), // test_expr_number_with_trailing_point
            ("${+.5}", .expression(.literal(0.5))), // test_expr_positive_leading_dot_decimal_literal
            ("${-0}", .expression(.literal(0))), // test_expr_negative_zero_literal
            ("${1e-999}", .expression(.literal(0))), // test_expr_exponent_underflow_is_zero
            ("${true}", .expression(.literal(true))), // test_expr_boolean_literals
            ("${trueish}", .expression(.path(DataPath("trueish")))), // test_expr_keyword_prefix_is_a_path
            ("${a-1}", .expression(.path(DataPath("a-1")))), // test_expr_hyphen_inside_path
            ("${.foo}", .expression(.path(DataPath(".foo")))), // test_expr_leading_dot_path_is_not_a_number
            ("${'line\\nbreak'}", .text("line\nbreak")), // test_expr_string_escapes
            ("${'a\\tb\\rc\\\\d'}", .text("a\tb\rc\\d")), // test_expr_string_escapes_tab_cr_backslash
            ("${'a\\qb'}", .text("aqb")), // test_expr_string_unknown_escape_keeps_character
            ("${'it\\'s'}", .text("it's")) // test_expr_string_escaped_quote
        ]
        for (template, segment) in cases {
            #expect(try A2UIExpressionParser.parseTemplate(template) == [segment], "\(template)")
        }
    }

    @Test("test_expr_null_keyword_produces_no_part: null interpolates as nothing")
    func null() throws {
        #expect(try A2UIExpressionParser.parseTemplate("a${null}b") == [.text("ab")])
        #expect(try A2UIExpressionParser.parseExpression("f(x: null)") == .call(name: "f", arguments: ["x": .literal("")]))
        #expect(try A2UIExpressionParser.parseTemplate("") == [])
    }

    @Test("test_expr_function_call_trailing_comma: a trailing comma is allowed")
    func trailingComma() throws {
        #expect(
            try A2UIExpressionParser.parseExpression("add(a: 1, b: 2,)")
                == .call(name: "add", arguments: ["a": .literal(1), "b": .literal(2)])
        )
    }

    @Test("Malformed templates throw the conformance suite's errors")
    func errors() {
        let cases: [(String, String)] = [
            ("hello ${world", "Unclosed interpolation"), // test_expr_error_unclosed_interpolation
            ("${add(a: 1, b: 2}", "after function arguments"), // test_expr_error_missing_closing_paren
            ("${add(a 1)}", "after argument name"), // test_expr_error_missing_arg_colon
            ("${f(1)}", "after argument name"), // test_expr_error_positional_function_arg
            ("${true false}", "Unexpected characters"), // test_expr_error_trailing_characters
            ("${a b}", "Unexpected characters"), // test_expr_error_space_separated_identifiers
            ("${-1x}", "Unexpected characters"), // test_expr_error_trailing_characters_after_number
            ("${1.2.3}", "Invalid number literal"), // test_expr_error_invalid_number_two_points
            ("${1e}", "Invalid number literal"), // test_expr_error_exponent_without_digits
            ("${.5e+}", "Invalid number literal"), // test_expr_error_leading_dot_exponent_sign_without_digits
            ("${1e999}", "out of range"), // test_expr_error_exponent_out_of_range
            ("${2e308}", "out of range"), // test_expr_error_mantissa_overflow_out_of_range
            ("${1" + String(repeating: "0", count: 310) + "}", "out of range") // test_expr_error_integer_out_of_range
        ]
        for (template, message) in cases {
            #expect(throws: A2UIExpressionError.self, "\(template)") {
                do {
                    _ = try A2UIExpressionParser.parseTemplate(template)
                } catch let error as A2UIExpressionError {
                    #expect(error.message.contains(message), "\(error.message)")
                    throw error
                }
            }
        }
    }

    @Test("test_expr_max_depth_nested_interpolations: 100 levels parse and 101 don't")
    func depth() throws {
        func nested(_ levels: Int) -> String {
            String(repeating: "${", count: levels) + "x" + String(repeating: "}", count: levels)
        }
        #expect(try A2UIExpressionParser.parseTemplate(nested(100)) == [.expression(.path(DataPath("x")))])
        #expect(throws: A2UIExpressionError("Max recursion depth reached in parse")) {
            try A2UIExpressionParser.parseTemplate(nested(101))
        }
        let calls = String(repeating: "f(a: ", count: 101) + "1" + String(repeating: ")", count: 101)
        #expect(throws: A2UIExpressionError.self) { try A2UIExpressionParser.parseTemplate("${\(calls)}") }
    }

    @Test("Templates over the length and part limits are rejected")
    func limits() {
        #expect(throws: A2UIExpressionError.self) {
            try A2UIExpressionParser.parseTemplate(String(repeating: "a", count: A2UIExpressionParser.maxTemplateLength + 1))
        }
        #expect(throws: A2UIExpressionError.self) {
            try A2UIExpressionParser.parseTemplate(String(repeating: "${x}", count: A2UIExpressionParser.maxTemplateParts + 1))
        }
        #expect(A2UIExpressionError("x").description == "x")
    }

    @Test("Braces inside quoted arguments do not end the expression")
    func quotedBraces() throws {
        let segments = try A2UIExpressionParser.parseTemplate("${formatDate(value: '}', format: 'y')}")
        #expect(segments == [.expression(.call(name: "formatDate", arguments: ["value": .literal("}"), "format": .literal("y")]))])
    }
}

@MainActor
@Suite("formatString evaluation")
struct InterpolationTests {
    @Test("Paths, functions and literals interpolate")
    func interpolation() throws {
        let (evaluator, model) = makeEvaluator(
            data: ["user": ["name": "Ada"] as JsonMap, "appName": "GenUI", "count": 2]
        )
        let context = DataContext(model, "/")

        #expect(
            try evaluator.interpolate("Hello, ${/user/name}! Welcome to ${/appName}.", in: context)
                == "Hello, Ada! Welcome to GenUI."
        )
        #expect(try evaluator.interpolate("Total: ${/count}", in: context) == "Total: 2")
    }

    @Test("Missing values interpolate as empty strings")
    func missingValues() throws {
        let (evaluator, model) = makeEvaluator()
        #expect(try evaluator.interpolate("[${/nope}]", in: DataContext(model, "/")) == "[]")
    }

    @Test("Relative paths interpolate inside a collection scope")
    func relativePaths() throws {
        let (evaluator, model) = makeEvaluator(data: ["items": [["name": "Tea", "quantity": 2] as JsonMap]])
        let scope = DataContext(model, "/").collectionScope(path: DataPath("/items"), index: 0)

        #expect(try evaluator.interpolate("${name} x${quantity}", in: scope) == "Tea x2")
        #expect(try evaluator.interpolate("#${@index(offset: 1)}", in: scope) == "#1")
    }

    @Test("Nested function calls interpolate")
    func nestedCalls() throws {
        let (evaluator, model) = makeEvaluator(data: ["price": 12.5])
        let context = DataContext(model, "/")

        #expect(
            try evaluator.interpolate("${formatCurrency(value: ${/price}, currency: 'USD')}", in: context)
                == "$12.50"
        )
    }

    @Test("Objects interpolate as JSON")
    func objectInterpolation() throws {
        let (evaluator, model) = makeEvaluator(data: ["point": ["x": 1] as JsonMap])
        #expect(try evaluator.interpolate("${/point}", in: DataContext(model, "/")) == "{\"x\":1}")
    }
}
