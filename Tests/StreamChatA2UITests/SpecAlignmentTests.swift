//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamChatA2UI
import Testing

/// Behaviour the A2UI 1.0 specification and its conformance suite
/// (`conformance/core/*.yaml` in github.com/a2ui-project/a2ui) define.
@MainActor
@Suite("Envelopes")
struct EnvelopeTests {
    @Test("Every message names version 1.0")
    func version() throws {
        #expect(A2UIProtocol.version == "1.0")
        #expect(throws: A2UIDecodingError.missingField("version", in: "envelope")) {
            try A2UIMessageDecoder.decode(["deleteSurface": [surfaceIdKey: "a"] as JsonMap])
        }
        #expect(throws: A2UIDecodingError.unsupportedVersion("v1.0")) {
            try A2UIMessageDecoder.decode(["version": "v1.0", "deleteSurface": [surfaceIdKey: "a"] as JsonMap])
        }
        #expect(throws: A2UIDecodingError.unsupportedVersion("1")) {
            try A2UIMessageDecoder.decode(["version": 1, "deleteSurface": [surfaceIdKey: "a"] as JsonMap])
        }
    }

    @Test("A message carries exactly one message type, as an object")
    func oneMessageType() {
        #expect(throws: A2UIDecodingError.self) {
            try A2UIMessageDecoder.decode([
                "version": "1.0",
                "createSurface": [surfaceIdKey: "a"] as JsonMap,
                "deleteSurface": [surfaceIdKey: "a"] as JsonMap
            ])
        }
        #expect(throws: A2UIDecodingError.invalidField("deleteSurface", in: "envelope", reason: "The message payload must be an object.")) {
            try A2UIMessageDecoder.decode(["version": "1.0", "deleteSurface": "a"])
        }
    }

    @Test("An updateDataModel path must be a JSON Pointer")
    func pointerPath() throws {
        #expect(throws: A2UIDecodingError.self) {
            try A2UIMessageDecoder.decode([
                "version": "1.0",
                "updateDataModel": [surfaceIdKey: "a", "path": "not_a_pointer", "value": 1] as JsonMap
            ])
        }
        let message = try A2UIMessageDecoder.decode([
            "version": "1.0",
            "updateDataModel": [surfaceIdKey: "a", "path": "", "value": 1] as JsonMap
        ])
        guard case let .updateDataModel(update) = message else {
            Issue.record("Expected an updateDataModel message")
            return
        }
        #expect(update.path.isRoot)
    }

    @Test("A function response carries exactly one of value and error")
    func functionResponseShape() throws {
        #expect(throws: A2UIDecodingError.self) {
            try FunctionResponse.fromJson(["functionCallId": "a"])
        }
        #expect(throws: A2UIDecodingError.self) {
            try FunctionResponse.fromJson(["functionCallId": "a", "value": 1, "error": ["code": "X", "message": "m"] as JsonMap])
        }
        #expect(throws: A2UIDecodingError.self) {
            try FunctionResponse.fromJson(["functionCallId": "a", "error": ["code": "X"] as JsonMap])
        }
        let empty = try FunctionResponse.fromJson(["functionCallId": "a", "value": NSNull()])
        #expect(empty.error == nil)
        #expect(empty.toJson().keys.contains("value"))
    }

    @Test("A malformed callRendererFunction keeps its call id")
    func malformedRendererCall() {
        let cases: [(JsonMap, String)] = [
            (["functionCallId": "c1"], "callFunction"),
            (["functionCallId": "c2", "callFunction": ["@call": "formatString", "catalogId": basicCatalogId, "args": "x"] as JsonMap], "args"),
            (["functionCallId": "c3", "callFunction": ["@call": "formatString", "args": ["value": "hi"] as JsonMap] as JsonMap], "catalogId"),
            (["functionCallId": "c4", "callFunction": ["catalogId": basicCatalogId] as JsonMap], "@call")
        ]
        for (payload, field) in cases {
            do {
                _ = try CallRendererFunctionMessage.fromJson(payload)
                Issue.record("Expected '\(field)' to be rejected")
            } catch let A2UIDecodingError.invalidFunctionCall(functionCallId, reason) {
                #expect(functionCallId == payload["functionCallId"] as? String)
                #expect(reason.contains(field))
            } catch {
                Issue.record("Unexpected error \(error)")
            }
        }
    }

    @Test("A callRendererFunction message round-trips its surface id")
    func rendererCallSurfaceId() throws {
        let call = CallRendererFunctionMessage(
            functionCallId: "c",
            callFunction: FunctionCall(name: "echo", catalogId: "cat"),
            surfaceId: "main"
        )
        let decoded = try CallRendererFunctionMessage.fromJson(call.toJson())
        #expect(decoded.surfaceId == "main")
        #expect(Json.map(call.toJson()["callFunction"])?["@call"] as? String == "echo")
    }

    @Test("Bindings and calls are written with the reserved @ keys")
    func reservedKeysOnTheWire() {
        #expect(Json.map(DynamicValue.binding(DataPath("/a")).rawValue)?["@path"] as? String == "/a")
        #expect(FunctionCall(name: "f").rawValue["@call"] as? String == "f")
        #expect(FunctionCall(["call": "f"]) == nil)
        #expect(DynamicValue(["path": "/a"]).bindingPath == nil)
    }
}

@MainActor
@Suite("Reporting to the agent")
struct AgentReportingTests {
    @Test("A message that fails to decode is reported with its surface")
    func decodeFailure() throws {
        let harness = ProcessorHarness()
        harness.processor.handle(json: ["version": "1.0", "deleteSurface": [:] as JsonMap])
        harness.processor.handle(json: ["version": "1.0", "updateComponents": [surfaceIdKey: "main"] as JsonMap])

        #expect(harness.errors.map(\.code) == [RendererError.Code.validationFailed, RendererError.Code.validationFailed])
        #expect(harness.errors[0].path == "/surfaceId")
        #expect(harness.errors[0].surfaceId == "")
        #expect(harness.errors[1].surfaceId == "main")
    }

    @Test("A malformed renderer call is answered with INVALID_FUNCTION_CALL")
    func malformedCallIsAnswered() throws {
        let harness = ProcessorHarness()
        harness.processor.handle(json: ["version": "1.0", "callRendererFunction": ["functionCallId": "c1"] as JsonMap])

        let error = try #require(harness.errors.first)
        #expect(error.code == RendererError.Code.invalidFunctionCall)
        #expect(error.functionCallId == "c1")
        #expect(error.surfaceId == nil)
        #expect(Json.map(RendererMessage.error(error).toJson()["error"])?["functionCallId"] as? String == "c1")
    }
}

@MainActor
@Suite("Surface lifecycle")
struct SurfaceLifecycleTests {
    @Test("A surface deleted or cleared and then created again shows in the view model its views hold")
    func recreatedSurfaceKeepsItsViewModel() {
        let harness = ProcessorHarness()
        harness.createSurface("main")
        let viewModel = harness.processor.surfaceViewModel("main")

        harness.processor.handle(.deleteSurface(DeleteSurfaceMessage(surfaceId: "main")))
        #expect(viewModel.definition == nil)
        harness.createSurface("main")
        #expect(harness.processor.surfaceViewModel("main") === viewModel)
        #expect(viewModel.definition != nil)

        harness.processor.clearSurfaces()
        #expect(viewModel.definition == nil)
        #expect(harness.processor.surfaceIds.isEmpty)
        harness.createSurface("main")
        #expect(harness.processor.surfaceViewModel("main") === viewModel)
        #expect(harness.processor.surfaceIds == ["main"])
    }

    @Test("Creating a surface that exists is an integrity error and keeps the original")
    func duplicateSurface() {
        let harness = ProcessorHarness()
        harness.createSurface(components: [Component(id: "root", type: "Text", properties: ["text": "first"])])
        harness.createSurface(components: [Component(id: "root", type: "Text", properties: ["text": "second"])])

        #expect(harness.errors.map(\.code) == [RendererError.Code.integrityError])
        let root = harness.processor.surfaceViewModel("main").definition?.root
        #expect(root?.properties["text"] as? String == "first")
    }

    @Test("A deleted surface can be created again, and its views reset")
    func deleteAndRecreate() {
        let harness = ProcessorHarness()
        harness.createSurface(components: [Component(id: "root", type: "Text")], dataModel: ["a": 1])
        let viewModel = harness.processor.surfaceViewModel("main")

        harness.processor.handle(.deleteSurface(DeleteSurfaceMessage(surfaceId: "main")))
        #expect(viewModel.definition == nil)
        #expect(viewModel.dataModel.snapshot.isEmpty)
        #expect(harness.processor.surfaceIds.isEmpty)

        harness.createSurface()
        #expect(harness.errors.isEmpty)
        #expect(harness.processor.surfaceIds == ["main"])
    }

    @Test("Deleting a surface that never existed does nothing")
    func deleteUnknownSurface() {
        let harness = ProcessorHarness()
        harness.processor.handle(.deleteSurface(DeleteSurfaceMessage(surfaceId: "ghost")))

        #expect(harness.outgoing.isEmpty)
        #expect(harness.updates.isEmpty)
    }

    @Test("A surface without a catalog is created without an error")
    func surfaceWithoutCatalog() {
        let harness = ProcessorHarness()
        harness.createSurface(catalogId: nil)

        #expect(harness.errors.isEmpty)
        #expect(harness.processor.surfaceIds == ["main"])
    }

    @Test("A repeated component id in one message is an integrity error")
    func duplicateIds() {
        let harness = ProcessorHarness()
        harness.createSurface()
        harness.processor.handle(
            .updateComponents(
                UpdateComponentsMessage(
                    surfaceId: "main",
                    components: [
                        Component(id: "root", type: "Text", properties: ["text": "First"]),
                        Component(id: "root", type: "Text", properties: ["text": "Duplicate"])
                    ]
                )
            )
        )

        #expect(harness.errors.map(\.code) == [RendererError.Code.integrityError])
        let root = harness.processor.surfaceViewModel("main").definition?.root
        #expect(root?.properties["text"] as? String == "First")
    }

    @Test("An unknown component type is reported with its position in the message")
    func unknownComponentType() throws {
        let harness = ProcessorHarness()
        harness.createSurface()
        harness.processor.handle(
            .updateComponents(
                UpdateComponentsMessage(
                    surfaceId: "main",
                    components: [Component(id: "a", type: "Text"), Component(id: "root", type: "NonExistentWidget")]
                )
            )
        )

        let error = try #require(harness.errors.first)
        #expect(error.code == RendererError.Code.validationFailed)
        #expect(error.path == "/components/1/component")
        #expect(error.surfaceId == "main")
    }

    @Test("A property that misuses the reserved @ prefix is reported")
    func reservedKeyMisuse() throws {
        let harness = ProcessorHarness()
        harness.createSurface(
            components: [Component(id: "root", type: "Text", properties: ["text": ["@if": true, "then": "x"] as JsonMap])]
        )

        let error = try #require(harness.errors.first)
        #expect(error.code == RendererError.Code.validationFailed)
        #expect(error.path == "/components/0/text")
    }

    @Test("Data model updates report integrity and data errors")
    func dataModelErrors() {
        let harness = ProcessorHarness()
        harness.processor.handle(.updateDataModel(UpdateDataModelMessage(surfaceId: "ghost", value: 1)))
        harness.createSurface(dataModel: ["user": "Alice"])
        harness.processor.handle(
            .updateDataModel(UpdateDataModelMessage(surfaceId: "main", path: DataPath("/user/name"), value: "Ada"))
        )

        #expect(harness.errors.map(\.code) == [RendererError.Code.integrityError, RendererError.Code.dataError])
        #expect(harness.processor.dataModel(for: "main").snapshot["user"] as? String == "Alice")
    }
}

@MainActor
@Suite("Agent-initiated function calls")
struct RendererFunctionCallTests {
    private func call(
        _ harness: ProcessorHarness,
        _ name: String,
        catalogId: String? = TestCatalog.catalogId,
        arguments: JsonMap = [:],
        surfaceId: String? = nil
    ) throws -> FunctionResponse {
        harness.processor.handle(
            .callRendererFunction(
                CallRendererFunctionMessage(
                    functionCallId: "call",
                    callFunction: FunctionCall(name: name, catalogId: catalogId, arguments: arguments),
                    surfaceId: surfaceId
                )
            )
        )
        return try #require(harness.functionResponses.last)
    }

    @Test("Arguments are evaluated against the named surface")
    func surfaceScope() throws {
        let harness = ProcessorHarness()
        harness.createSurface(dataModel: ["name": "Ada"])

        let response = try call(harness, "agentOnly", arguments: ["value": ["@path": "/name"]], surfaceId: "main")
        #expect(Json.string(response.value) == "agent:Ada")
    }

    @Test("Without a surface, arguments read an empty data model")
    func emptyScope() throws {
        let harness = ProcessorHarness()
        harness.createSurface(dataModel: ["name": "Ada"])

        let response = try call(harness, "agentOnly", arguments: ["value": ["@path": "/name"]])
        #expect(Json.string(response.value) == "agent:")
    }

    @Test("Calls the renderer cannot honour are answered with INVALID_FUNCTION_CALL")
    func invalidCalls() throws {
        let harness = ProcessorHarness()
        let rejected = [
            try call(harness, "agentOnly", surfaceId: "ghost"),
            try call(harness, "agentOnly", catalogId: "missing-catalog"),
            try call(harness, "agentOnly", catalogId: nil),
            try call(harness, "openUrl", catalogId: TestCatalog.catalogId, arguments: ["url": "https://a.b"])
        ]
        for response in rejected {
            #expect(response.error?.code == RendererError.Code.invalidFunctionCall)
        }
        #expect(harness.errors.isEmpty)
    }

    @Test("@index outside a list template fails the call")
    func indexAtRoot() throws {
        let harness = ProcessorHarness()
        let response = try call(harness, "agentOnly", arguments: ["value": ["@call": "@index"]])

        #expect(response.error?.code == RendererError.Code.executionError)
    }

    @Test("A function with no result answers with null")
    func voidResult() throws {
        let catalog = TestCatalog.make(recorder: RenderRecorder()).adding(
            functions: [
                FunctionDefinition(name: "ping", description: "Returns nothing.", returnType: .void, allowedCallers: .agentOnly) { _ in nil }
            ]
        )
        let harness = ProcessorHarness(catalogs: [catalog])
        let response = try call(harness, "ping")

        #expect(response.error == nil)
        #expect(response.toJson()["value"] is NSNull)
    }

    @Test("An agent function that never answers times out")
    func agentFunctionTimeout() async throws {
        let processor = A2UIMessageProcessor(
            catalogs: [TestCatalog.make(recorder: RenderRecorder())],
            services: TestServices.make(),
            agentFunctionTimeout: 0.01
        )
        processor.handle(.createSurface(CreateSurfaceMessage(surfaceId: "main", catalogId: TestCatalog.catalogId)))
        let revision = processor.surfaceViewModel("main").revision

        #expect(try processor.agentFunctionValue(for: "estimate", catalogId: nil, arguments: [:], surfaceId: "main") == nil)
        await waitUntil("the call times out") { processor.surfaceViewModel("main").revision > revision }

        #expect(throws: A2UIFunctionError.self) {
            try processor.agentFunctionValue(for: "estimate", catalogId: nil, arguments: [:], surfaceId: "main")
        }
    }
}
