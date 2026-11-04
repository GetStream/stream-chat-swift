//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import Testing

@MainActor
@Suite("Agent to renderer messages")
struct AgentMessageTests {
    @Test("createSurface carries components and an initial data model")
    func createSurface() throws {
        let message = try decodeMessage(
            """
            {
              "version": "1.0",
              "createSurface": {
                "surfaceId": "main",
                "catalogId": "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json",
                "sendDataModel": true,
                "components": [
                  {"id": "root", "component": "Text", "text": {"@path": "/name"}}
                ],
                "dataModel": {"name": "Ada"}
              }
            }
            """
        )

        guard case let .createSurface(payload) = message else {
            Issue.record("Expected a createSurface message, got \(message)")
            return
        }
        #expect(payload.surfaceId == "main")
        #expect(payload.catalogId == basicCatalogId)
        #expect(payload.sendDataModel)
        #expect(payload.components.count == 1)
        #expect(payload.components[0].type == "Text")
        #expect(Json.string(payload.dataModel?["name"]) == "Ada")
    }

    @Test("updateComponents requires a surface id")
    func updateComponentsValidation() {
        let json: JsonMap = ["version": "1.0", "updateComponents": ["components": JsonArray()] as JsonMap]
        #expect(throws: A2UIDecodingError.missingField(surfaceIdKey, in: "updateComponents")) {
            try A2UIMessageDecoder.decode(json)
        }
    }

    @Test("updateDataModel defaults to the root path and keeps explicit nulls")
    func updateDataModel() throws {
        let rootUpdate = try decodeMessage(
            """
            {"version": "1.0", "updateDataModel": {"surfaceId": "main", "value": {"a": 1}}}
            """
        )
        guard case let .updateDataModel(payload) = rootUpdate else {
            Issue.record("Expected an updateDataModel message")
            return
        }
        #expect(payload.path.isRoot)

        let deletion = try decodeMessage(
            """
            {"version": "1.0", "updateDataModel": {"surfaceId": "main", "path": "/a/b", "value": null}}
            """
        )
        guard case let .updateDataModel(deletePayload) = deletion else {
            Issue.record("Expected an updateDataModel message")
            return
        }
        #expect(deletePayload.path.description == "/a/b")
        #expect(deletePayload.value == nil)
    }

    @Test("updateDataModel requires a value")
    func updateDataModelRequiresValue() {
        let json: JsonMap = ["version": "1.0", "updateDataModel": [surfaceIdKey: "main"] as JsonMap]
        #expect(throws: A2UIDecodingError.missingField("value", in: "updateDataModel")) {
            try A2UIMessageDecoder.decode(json)
        }
    }

    @Test("deleteSurface names the surface to remove")
    func deleteSurface() throws {
        let message = try decodeMessage(#"{"version": "1.0", "deleteSurface": {"surfaceId": "main"}}"#)
        #expect(message.surfaceId == "main")
    }

    @Test("callRendererFunction carries the call id and function")
    func callRendererFunction() throws {
        let message = try decodeMessage(
            """
            {
              "version": "1.0",
              "callRendererFunction": {
                "functionCallId": "call-1",
                "callFunction": {"@call": "getInfo", "catalogId": "app:catalog", "args": {"index": 0}}
              }
            }
            """
        )
        guard case let .callRendererFunction(payload) = message else {
            Issue.record("Expected a callRendererFunction message")
            return
        }
        #expect(payload.functionCallId == "call-1")
        #expect(payload.callFunction.name == "getInfo")
        #expect(payload.callFunction.catalogId == "app:catalog")
        #expect(Json.int(payload.callFunction.arguments["index"]) == 0)
    }

    @Test("agentFunctionResponse decodes values and errors")
    func agentFunctionResponse() throws {
        let success = try decodeMessage(
            #"{"version": "1.0", "agentFunctionResponse": {"functionCallId": "c1", "value": [1920, 1080]}}"#
        )
        guard case let .agentFunctionResponse(response) = success else {
            Issue.record("Expected an agentFunctionResponse message")
            return
        }
        #expect(Json.array(response.value)?.count == 2)
        #expect(response.error == nil)

        let failure = try decodeMessage(
            """
            {
              "version": "1.0",
              "agentFunctionResponse": {
                "functionCallId": "c1",
                "error": {"code": "NOT_FOUND", "message": "missing"}
              }
            }
            """
        )
        guard case let .agentFunctionResponse(errorResponse) = failure else {
            Issue.record("Expected an agentFunctionResponse message")
            return
        }
        #expect(errorResponse.error?.code == "NOT_FOUND")
    }

    @Test("A different protocol version is rejected")
    func versionMismatch() {
        let json: JsonMap = ["version": "v0.9", "beginRendering": [surfaceIdKey: "main"] as JsonMap]
        #expect(throws: A2UIDecodingError.unsupportedVersion("v0.9")) {
            try A2UIMessageDecoder.decode(json)
        }
    }

    @Test("An unknown message type is rejected")
    func unknownMessage() {
        #expect(throws: (any Error).self) {
            try A2UIMessageDecoder.decode(["version": "1.0", "somethingElse": [:] as JsonMap])
        }
    }

    @Test("Message lists keep going after a failing message")
    func listDecoding() {
        let values: JsonArray = [
            ["version": "1.0", "createSurface": [surfaceIdKey: "a"] as JsonMap] as JsonMap,
            ["version": "1.0", "unknown": [:] as JsonMap] as JsonMap,
            ["version": "1.0", "deleteSurface": [surfaceIdKey: "a"] as JsonMap] as JsonMap
        ]
        let result = A2UIMessageDecoder.decodeList(values)

        #expect(result.messages.count == 2)
        #expect(result.errors.count == 1)
    }

    @Test("Messages round-trip through their wire representation")
    func roundTrip() throws {
        let original = A2UIMessage.updateComponents(
            UpdateComponentsMessage(
                surfaceId: "main",
                components: [
                    Component(
                        id: "root",
                        type: "Column",
                        accessibility: AccessibilityAttributes(label: .literal("Menu")),
                        properties: ["children": ["a", "b"]]
                    )
                ]
            )
        )
        let decoded = try A2UIMessageDecoder.decode(original.toJson())

        #expect(decoded == original)
        #expect(original.toJson()[A2UIProtocol.versionKey] as? String == "1.0")
    }

    @Test("Only known message keys are recognized")
    func messageDetection() {
        #expect(A2UIMessageDecoder.isMessage(["createSurface": [:] as JsonMap]))
        #expect(!A2UIMessageDecoder.isMessage(["action": [:] as JsonMap]))
    }
}

@MainActor
@Suite("Renderer to agent messages")
struct RendererMessageTests {
    @Test("Actions serialize every required field")
    func actionEncoding() throws {
        let action = RendererAction(
            name: "submit",
            userMessage: "Submitted the form",
            surfaceId: "main",
            sourceComponentId: "button",
            timestamp: TestServices.referenceDate,
            context: ["email": "a@b.com"]
        )
        let json = RendererMessage.action(action).toJson()

        #expect(json[A2UIProtocol.versionKey] as? String == "1.0")
        let payload = try #require(Json.map(json["action"]))
        #expect(payload["name"] as? String == "submit")
        #expect(payload[surfaceIdKey] as? String == "main")
        #expect(payload["sourceComponentId"] as? String == "button")
        #expect(payload["timestamp"] as? String == "2026-01-01T00:00:00Z")
        #expect(Json.string(Json.map(payload["context"])?["email"]) == "a@b.com")
    }

    @Test("Renderer messages round-trip")
    func roundTrip() throws {
        let messages: [RendererMessage] = [
            .action(
                RendererAction(
                    name: "tap",
                    surfaceId: "main",
                    sourceComponentId: "button",
                    timestamp: TestServices.referenceDate,
                    context: [:]
                )
            ),
            .callAgentFunction(
                CallAgentFunctionMessage(
                    surfaceId: "main",
                    functionCallId: "c1",
                    callFunction: FunctionCall(name: "verify", arguments: ["id": "1"])
                )
            ),
            .rendererFunctionResponse(FunctionResponse(functionCallId: "c1", value: 42)),
            .error(
                RendererError(
                    code: RendererError.Code.unallowedParent,
                    message: "no",
                    surfaceId: "main",
                    path: "/components/0"
                )
            )
        ]

        for message in messages {
            let decoded = try RendererMessage.fromJson(message.toJson())
            #expect(decoded == message)
        }
    }

    @Test("Errors require a code and a message")
    func errorValidation() {
        #expect(throws: A2UIDecodingError.missingField("code", in: "error")) {
            try RendererError.fromJson(["message": "no code"])
        }
    }

    @Test("Timestamps parse with and without fractional seconds")
    func timestamps() {
        #expect(A2UITimestamp.date(from: "2026-01-01T00:00:00Z") == TestServices.referenceDate)
        #expect(A2UITimestamp.date(from: "2026-01-01T00:00:00.500Z") != nil)
        #expect(A2UITimestamp.date(from: "not a date") == nil)
    }
}
