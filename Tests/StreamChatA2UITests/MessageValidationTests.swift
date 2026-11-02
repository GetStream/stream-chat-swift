//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamChatA2UI
import Testing

/// What the processor reports when components and data arrive, as the A2UI 1.0
/// conformance suite (`conformance/core/*.yaml`) defines it.
@MainActor
@Suite("Message validation")
struct MessageValidationTests {
    private func harness(_ components: [JsonMap], dataModel: JsonMap? = nil, catalogId: String? = BasicCatalog.catalogId) -> ProcessorHarness {
        let harness = ProcessorHarness(catalogs: [BasicCatalog.catalog])
        var surface: JsonMap = ["surfaceId": "s", "components": components as JsonArray]
        if let catalogId { surface["catalogId"] = catalogId }
        if let dataModel { surface["dataModel"] = dataModel }
        harness.processor.handle(json: ["version": "1.0", "createSurface": surface])
        return harness
    }

    private func reported(_ harness: ProcessorHarness) -> [String] {
        harness.errors.map { "\($0.code) \($0.path ?? "")" }
    }

    @Test("test_v10_create_surface_metadata_extension_key_must_be_identifier and _only_holds_extensions")
    func surfaceMetadata() {
        let harness = ProcessorHarness(catalogs: [BasicCatalog.catalog])
        for metadata in [["extensions": ["a2ui:experimental": true] as JsonMap] as JsonMap, ["owner": "me"]] {
            harness.processor.handle(json: ["version": "1.0", "createSurface": ["surfaceId": "bad", "metadata": metadata] as JsonMap])
        }
        harness.processor.handle(json: ["version": "1.0", "createSurface": ["surfaceId": "bad", "metadata": "x"] as JsonMap])

        #expect(reported(harness) == [
            "VALIDATION_FAILED /metadata/extensions/a2ui:experimental", "VALIDATION_FAILED /metadata/owner", "VALIDATION_FAILED /metadata"
        ])
        #expect(harness.processor.surfaceViewModel("bad").definition == nil)

        harness.processor.handle(json: [
            "version": "1.0",
            "createSurface": ["surfaceId": "good", "metadata": ["extensions": ["a2ui_experimental": ["streaming": true] as JsonMap] as JsonMap] as JsonMap] as JsonMap
        ])
        #expect(harness.processor.surfaceViewModel("good").definition != nil)
    }

    @Test("test_v10_update_components_metadata_extension_key_must_be_identifier_on_update keeps the stored metadata")
    func componentMetadata() {
        let harness = harness([["id": "root", "component": "Text", "text": "Hi", "metadata": ["extensions": ["com_example_trace": "t1"] as JsonMap] as JsonMap]])
        harness.processor.handle(json: [
            "version": "1.0",
            "updateComponents": ["surfaceId": "s", "components": [
                ["id": "root", "component": "Text", "text": "Hi", "metadata": ["extensions": ["com-example-trace": "t2"] as JsonMap] as JsonMap] as JsonMap
            ] as JsonArray] as JsonMap
        ])

        #expect(reported(harness) == ["VALIDATION_FAILED /components/0/metadata/extensions/com-example-trace"])
        let metadata = harness.processor.surfaceViewModel("s").definition?.component("root")?.metadata
        #expect(Json.map(metadata?["extensions"])?["com_example_trace"] as? String == "t1")
    }

    @Test("test_v10_uax31_invalid_identifier_error: component ids are Unicode identifiers")
    func componentIds() {
        let harness = harness([
            ["id": "root", "component": "Column", "children": ["123invalid_id"]],
            ["id": "123invalid_id", "component": "Text", "text": "x"]
        ])
        #expect(reported(harness) == ["VALIDATION_FAILED /components/1/id"])
        #expect(harness.errors.first?.message == "Component id '123invalid_id' must be a valid UAX #31 identifier.")
    }

    @Test("test_v10_child_list_template_missing_path_error")
    func templateWithoutPath() {
        let harness = harness([["id": "root", "component": "List", "children": ["componentId": "item"] as JsonMap]])
        #expect(reported(harness) == ["VALIDATION_FAILED /components/0/children"])
    }

    @Test("test_v10_invalid_binding_path_error and test_v10_update_data_model_invalid_path_error")
    func pathSyntax() {
        let harness = harness([["id": "root", "component": "Text", "text": ["@path": "/invalid/escape/~2"] as JsonMap]])
        harness.processor.handle(json: ["version": "1.0", "updateDataModel": ["surfaceId": "s", "path": "/user/~2invalid", "value": "Alice"] as JsonMap])

        #expect(reported(harness) == ["VALIDATION_FAILED /components/0/text", "VALIDATION_FAILED /path"])
        #expect(harness.errors.allSatisfy { $0.message.contains("Invalid path syntax") })
        #expect(DataPath.isValidSyntax("/a~0b/c~1d"))
        #expect(!DataPath.isValidSyntax("/a~"))
    }

    @Test("test_v10_function_call_with_empty_name_errors and test_v10_undefined_system_function_errors")
    func functionNames() {
        let harness = harness([
            ["id": "root", "component": "Column", "children": ["a", "b"]],
            ["id": "a", "component": "Text", "text": ["@call": ""] as JsonMap],
            ["id": "b", "component": "Text", "text": ["@call": "@foo"] as JsonMap]
        ])
        #expect(harness.errors.map(\.message) == [
            "The function name '' must be a valid UAX #31 identifier.", "Unknown system function '@foo'."
        ])
    }

    @Test("test_v10_function_call_naming_unknown_catalog_errors, _with_non_string_catalog_id and _on_surface_without_default")
    func callCatalogs() {
        let harness = harness([
            ["id": "root", "component": "Column", "children": ["a", "b"]],
            ["id": "a", "component": "Text", "text": ["@call": "formatString", "catalogId": "missing-catalog", "args": ["value": "x"] as JsonMap] as JsonMap],
            ["id": "b", "component": "Text", "text": ["@call": "formatString", "catalogId": 7, "args": ["value": "x"] as JsonMap] as JsonMap]
        ])
        #expect(reported(harness) == ["CATALOG_NOT_FOUND /components/1/text", "VALIDATION_FAILED /components/2/text/catalogId"])
        #expect(harness.errors.first?.message == "Catalog not found: missing-catalog")

        let withoutDefault = self.harness(
            [["id": "root", "component": "Text", "catalogId": BasicCatalog.catalogId, "text": ["@call": "formatString", "args": ["value": "x"] as JsonMap] as JsonMap]],
            catalogId: nil
        )
        #expect(withoutDefault.errors.map(\.message) == ["Function 'formatString' has no catalogId, and the surface has no default catalogId."])
    }

    @Test("test_v10_function_argument_schema_mismatch_error: literal arguments are checked against the function")
    func callArguments() {
        let harness = harness([
            ["id": "root", "component": "Column", "children": ["a", "b", "c"]],
            ["id": "a", "component": "Text", "text": ["@call": "formatString", "args": [:] as JsonMap] as JsonMap],
            ["id": "b", "component": "Text", "text": ["@call": "formatNumber", "args": ["value": 1, "decimals": "two"] as JsonMap] as JsonMap],
            ["id": "c", "component": "Text", "text": ["@call": "formatNumber", "args": ["value": ["@path": "/n"] as JsonMap, "extra": 1] as JsonMap] as JsonMap]
        ])
        #expect(reported(harness) == [
            "VALIDATION_FAILED /components/1/text/args", "VALIDATION_FAILED /components/2/text/args/decimals", "VALIDATION_FAILED /components/3/text/args/extra"
        ])
    }

    @Test("test_v10_recursion_limit_function_call_depth_exceeded_error")
    func callDepth() {
        var call: JsonMap = ["@call": "formatString", "args": ["value": "x"] as JsonMap]
        for _ in 0..<A2UIProtocol.maxFunctionCallDepth {
            call = ["@call": "formatString", "args": ["value": call] as JsonMap]
        }
        let harness = harness([["id": "root", "component": "Text", "text": call]])
        #expect(harness.errors.map(\.message) == ["The functionCall depth of 'text' exceeds 5."])
    }

    @Test("test_global_recursion_depth_limit_exceeded_error and test_v10_data_model_nesting_depth_limit_exceeded_error")
    func valueDepth() {
        var deep: JsonMap = ["leaf": "too deep"]
        for level in 0..<A2UIProtocol.maxNestingDepth {
            deep = ["l\(level)": deep]
        }
        let harness = harness([["id": "root", "component": "Text", "text": "Deep", "meta": deep]], dataModel: deep)
        harness.processor.handle(json: ["version": "1.0", "updateDataModel": ["surfaceId": "s", "path": "/x", "value": deep] as JsonMap])

        #expect(reported(harness) == ["RECURSION_LIMIT_EXCEEDED /components/0", "RECURSION_LIMIT_EXCEEDED /dataModel", "RECURSION_LIMIT_EXCEEDED /value"])
        #expect(harness.processor.surfaceViewModel("s").definition?.component("root") == nil)
        #expect(harness.processor.dataModel(for: "s").value(at: .root).map { Json.map($0)?.isEmpty } == true)
        #expect(Json.exceedsDepth(["a": [1]] as JsonMap, limit: 2) == false)
    }

    @Test("test_expression_parser_syntax_error_unclosed_brace: a literal template that doesn't parse")
    func brokenTemplate() {
        let harness = harness([["id": "root", "component": "Text", "text": ["@call": "formatString", "args": ["value": "Hello ${/unclosed"] as JsonMap] as JsonMap]])
        #expect(reported(harness) == ["VALIDATION_FAILED /components/0/text/args/value"])
        #expect(harness.errors.first?.message == "Unclosed interpolation: missing '}'")
    }
}

@MainActor
@Suite("Function evaluation errors")
struct FunctionEvaluationErrorTests {
    @Test("test_index_function_outside_loop_error and unknown system functions are reported")
    func systemFunctions() {
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(router: router)
        let context = DataContext(model, "/")

        #expect(evaluator.invoke(FunctionCall(name: "@index"), in: context) == nil)
        #expect(evaluator.invoke(FunctionCall(name: "@foo"), in: context) == nil)
        #expect(router.errors.map(\.message) == [
            "@index function can only be evaluated inside a collection template iteration scope.", "Unknown system function '@foo'."
        ])
        #expect(router.errors.allSatisfy { $0.code == RendererError.Code.expressionError })
    }

    @Test("A template that doesn't parse fails formatString with EXPRESSION_ERROR")
    func brokenTemplate() {
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(catalogs: [BasicCatalog.catalog], surfaceCatalogId: BasicCatalog.catalogId, router: router)

        #expect(evaluator.invoke(FunctionCall(name: "formatString", arguments: ["value": "${a b}"]), in: DataContext(model, "/")) == nil)
        #expect(router.errors.map(\.code) == [RendererError.Code.expressionError])
        #expect(A2UIErrorFormatter.describe(A2UIExpressionError("Bad.")) == "Bad.")
    }
}

@MainActor
@Suite("Agent function calls")
struct AgentFunctionCallTests {
    private func harness() -> ProcessorHarness {
        let echo = FunctionDefinition(
            name: "echoArgs",
            description: "Returns its arguments.",
            arguments: JsonSchema.object(
                properties: ["leaked": JsonSchema.dynamicValue(), "constant": JsonSchema.dynamicString(), "amount": ["type": "number"]],
                additionalProperties: false
            ),
            returnType: .object,
            allowedCallers: .rendererOrAgent
        ) { invocation in invocation.arguments as JsonMap }
        let open = FunctionDefinition(
            name: "openExternalUrl",
            description: "Opens a link.",
            returnType: .void,
            allowedCallers: .rendererOrAgent,
            requiresUserActivation: true
        ) { _ in nil }
        return ProcessorHarness(catalogs: [Catalog(catalogId: "media", functions: [echo, open])])
    }

    private func call(_ harness: ProcessorHarness, _ function: String, _ args: JsonMap) -> FunctionResponse? {
        harness.processor.handle(json: [
            "version": "1.0",
            "callRendererFunction": ["functionCallId": "c1", "callFunction": ["@call": function, "catalogId": "media", "args": args] as JsonMap] as JsonMap
        ])
        return harness.functionResponses.last
    }

    @Test("test_rpc_call_renderer_function_without_surface_id_isolated_data_model: a missing binding is null")
    func missingBinding() {
        let response = call(harness(), "echoArgs", ["leaked": ["@path": "/secret"] as JsonMap, "constant": "safe"])

        let value = Json.map(response?.value)
        #expect(value?["leaked"] is NSNull)
        #expect(value?["constant"] as? String == "safe")
    }

    @Test("test_rpc_call_renderer_function_invalid_argument_schema answers INVALID_FUNCTION_CALL")
    func invalidArguments() {
        let response = call(harness(), "echoArgs", ["amount": "invalid_string_amount"])

        #expect(response?.error?.code == RendererError.Code.invalidFunctionCall)
        #expect(response?.error?.message == "Invalid arguments for 'echoArgs': '/amount' must be number.")
    }

    @Test("A function that needs a user gesture can't be called by the agent")
    func userActivation() {
        let response = call(harness(), "openExternalUrl", [:])

        #expect(response?.error?.message == "Function 'openExternalUrl' requires a user gesture, which a call from the agent doesn't have.")
        #expect(FunctionDefinition(name: "f", description: "", returnType: .void, allowedCallers: .rendererOrAgent, requiresUserActivation: true) { _ in nil }
            .allowedCallers == .rendererOrAgent)
    }
}

@MainActor
@Suite("Data model writes")
struct DataModelWriteTests {
    @Test("test_data_model_sparse_list_write_pads_with_null and test_data_model_rejects_excessive_list_index")
    func sparseWrites() throws {
        let model = DataModel([:])
        try model.set(42, at: DataPath("/data/lists/1/value"))

        let list = try #require(Json.array(model.value(at: DataPath("/data/lists"))))
        #expect(list.count == 2)
        #expect(list[0] is NSNull)
        #expect(Json.int(model.value(at: DataPath("/data/lists/1/value"))) == 42)

        let items = DataModel(["items": ["a", "b", "c"]])
        try items.set("max", at: DataPath("/items/10000"))
        #expect(Json.array(items.value(at: DataPath("/items")))?.count == 10001)
        #expect(throws: DataModelError.self) { try items.set("x", at: DataPath("/items/10001")) }
    }

    @Test("test_resolve_path_dot_in_scoped_context and _in_root_context")
    func dotPaths() {
        #expect(DataPath("/user").appending(DataPath(".")) == DataPath("/user"))
        #expect(DataPath("/").appending(DataPath(".")) == DataPath("/"))
        #expect(DataPath("/user").appending(DataPath("./name")) == DataPath("/user/name"))
    }
}

@MainActor
@Suite("JSON Schema checks")
struct JsonSchemaValidatorTests {
    private func violation(_ value: (any Sendable)?, _ schema: JsonMap, dynamic: Bool = false) -> String? {
        JsonSchemaValidator.violation(of: value, against: schema, allowsDynamicValues: dynamic)?.message
    }

    @Test("Types, enums, constants and bounds")
    func scalars() {
        #expect(violation("a", ["type": "string"]) == nil)
        #expect(violation(1, ["type": "string"]) == "The arguments must be string")
        #expect(violation(1.5, ["type": "integer"]) != nil)
        #expect(violation(2, ["type": ["integer", "null"]]) == nil)
        #expect(violation(NSNull(), ["type": "null"]) == nil)
        #expect(violation(true, ["type": "number"]) != nil)
        #expect(violation("b", ["enum": ["a"]]) != nil)
        #expect(violation("b", ["const": "a"]) != nil)
        #expect(violation(5, ["minimum": 6]) != nil)
        #expect(violation(5, ["maximum": 4]) != nil)
        #expect(violation([1] as JsonArray, ["type": "boolean"]) != nil)
        #expect(violation([:] as JsonMap, ["type": "array"]) != nil)
        #expect(violation("x", ["type": "custom"]) == nil)
    }

    @Test("Objects, arrays and combinators")
    func structures() {
        let object: JsonMap = ["properties": ["a": ["type": "number"] as JsonMap] as JsonMap, "required": ["a"], "additionalProperties": false]
        #expect(violation(["a": 1] as JsonMap, object) == nil)
        #expect(violation([:] as JsonMap, object) == "The arguments must have 'a'")
        #expect(JsonSchemaValidator.violation(of: ["a": 1, "b": 2] as JsonMap, against: object)?.pointer == "/b")
        #expect(violation(["b": 2] as JsonMap, ["additionalProperties": ["type": "string"] as JsonMap]) != nil)

        let array: JsonMap = ["items": ["type": "string"] as JsonMap, "minItems": 1, "maxItems": 2]
        #expect(violation(["a"] as JsonArray, array) == nil)
        #expect(violation([] as JsonArray, array) != nil)
        #expect(violation(["a", "b", "c"] as JsonArray, array) != nil)
        #expect(JsonSchemaValidator.violation(of: ["a", 1] as JsonArray, against: array)?.pointer == "/1")

        #expect(violation(1, ["anyOf": [["type": "string"] as JsonMap, ["type": "number"] as JsonMap] as JsonArray]) == nil)
        #expect(violation(true, ["oneOf": [["type": "string"] as JsonMap] as JsonArray]) != nil)
        #expect(violation(1, ["allOf": [["type": "number"] as JsonMap, ["minimum": 2] as JsonMap] as JsonArray]) != nil)
    }

    @Test("Common Dynamic types accept the values a binding or call resolves to")
    func dynamicTypes() {
        func reference(_ name: String) -> JsonMap {
            JsonSchema.commonType(name)
        }
        #expect(violation(1, reference("DynamicString")) == nil)
        #expect(violation([1] as JsonArray, reference("DynamicString")) != nil)
        #expect(violation("2.5", reference("DynamicNumber")) == nil)
        #expect(violation("x", reference("DynamicNumber")) != nil)
        #expect(violation(1, reference("DynamicBoolean")) != nil)
        #expect(violation("x", reference("DynamicStringList")) != nil)
        #expect(violation("x", reference("ChildList")) == nil)
        #expect(violation(["@path": "/a"] as JsonMap, ["type": "number"], dynamic: true) == nil)
        #expect(violation(["@path": "/a"] as JsonMap, ["type": "number"]) != nil)
    }
}
