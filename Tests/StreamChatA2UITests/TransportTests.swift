//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamChatA2UI
import Testing

@MainActor
@Suite("A2A connector: outgoing")
struct ConnectorRequestTests {
    private func send(_ request: GenerationRequest) async -> A2AMessageSendParams {
        let client = MockA2AClient()
        let connector = A2UIAgentConnector(url: URL(string: "https://example.com")!, client: client)
        await connector.send(request)
        return client.sentPayloads[0]
    }

    @Test("The A2UI extension is activated on every request")
    func extensionActivation() async {
        let payload = await send(GenerationRequest(userMessage: .text("hi")))
        #expect(payload.extensions == [A2UIProtocol.a2aExtensionUri])
        #expect(payload.extensions[0] == "https://a2ui.org/a2a-extension/a2ui/v1.0")
    }

    @Test("Renderer capabilities and data models travel in message metadata")
    func metadata() async throws {
        let payload = await send(
            GenerationRequest(
                userMessage: .text("hi"),
                capabilities: RendererCapabilities(supportedCatalogIds: [basicCatalogId]),
                dataModel: RendererDataModel(surfaces: ["main": ["a": 1]])
            )
        )

        let metadata = try #require(payload.message.metadata)
        let capabilities = try #require(Json.map(metadata[A2UIProtocol.rendererCapabilitiesKey]))
        #expect(Json.stringArray(Json.map(capabilities["1.0"])?["supportedCatalogIds"]) == [basicCatalogId])

        let dataModel = try #require(Json.map(metadata[A2UIProtocol.rendererDataModelKey]))
        #expect(dataModel[A2UIProtocol.versionKey] as? String == "1.0")
        #expect(Json.map(Json.map(dataModel["surfaces"])?["main"]) != nil)
    }

    @Test("An empty data model is not attached")
    func emptyDataModel() async {
        let payload = await send(
            GenerationRequest(userMessage: .text("hi"), dataModel: RendererDataModel(surfaces: [:]))
        )
        #expect(payload.message.metadata?[A2UIProtocol.rendererDataModelKey] == nil)
    }

    @Test("Renderer events are sent as one A2UI data part")
    func rendererMessages() async throws {
        let action = RendererAction(
            name: "submit",
            surfaceId: "main",
            sourceComponentId: "button",
            timestamp: TestServices.referenceDate,
            context: [:]
        )
        let payload = await send(
            GenerationRequest(
                userMessage: .text("done"),
                rendererMessages: [.action(action), .error(RendererError(code: "X", message: "y", surfaceId: "main"))]
            )
        )

        let dataPart = try #require(payload.message.parts.compactMap { $0 as? A2ADataPart }.first)
        #expect(dataPart.metadata?["mimeType"] as? String == "application/a2ui+json")
        let messages = try #require(dataPart.dataArray)
        #expect(messages.count == 2)
        #expect(Json.map(messages[0])?["action"] != nil)
        #expect(Json.map(messages[1])?["error"] != nil)

        let textPart = try #require(payload.message.parts.compactMap { $0 as? A2ATextPart }.first)
        #expect(textPart.text == "done")
    }

    @Test("Image parts are encoded as A2A file parts")
    func imageParts() async throws {
        let payload = await send(
            GenerationRequest(
                userMessage: UserMessage([
                    TextPart("look"),
                    ImagePart.url(URL(string: "https://example.com/a.png")!, mimeType: "image/png"),
                    ImagePart.bytes(Data([1, 2, 3]), mimeType: "image/png")
                ])
            )
        )

        let fileParts = payload.message.parts.compactMap { $0 as? A2AFilePart }
        #expect(fileParts.count == 2)
        #expect((fileParts[0].file as? A2AFileWithUri)?.uri == "https://example.com/a.png")
        #expect((fileParts[1].file as? A2AFileWithBytes)?.bytes == Data([1, 2, 3]).base64EncodedString())
    }

    @Test("Task and context ids are carried into follow-up requests")
    func taskContinuity() async throws {
        let client = MockA2AClient(events: [
            A2ASendStreamMessageSuccessResponse(result: A2ATask(id: "task-1", contextId: "ctx-1"), id: 1)
        ])
        let connector = A2UIAgentConnector(url: URL(string: "https://example.com")!, client: client)

        await connector.send(GenerationRequest(userMessage: .text("first")))
        await connector.send(GenerationRequest(userMessage: .text("second")))

        #expect(connector.taskId == "task-1")
        #expect(connector.contextId == "ctx-1")
        let second = client.sentPayloads[1].message
        #expect(second.referenceTaskIds == ["task-1"])
        #expect(second.contextId == "ctx-1")
    }
}

@MainActor
@Suite("A2A connector: incoming")
struct ConnectorResponseTests {
    private func receive(
        _ events: [A2ASendStreamMessageResponse]
    ) async -> (messages: [A2UIMessage], text: String?, errors: [Error]) {
        let client = MockA2AClient(events: events)
        let connector = A2UIAgentConnector(url: URL(string: "https://example.com")!, client: client)

        var messages: [A2UIMessage] = []
        var errors: [Error] = []
        let subscriptions = [
            connector.messages.sink { messages.append($0) },
            connector.errors.sink { errors.append($0) }
        ]
        let text = await connector.send(GenerationRequest(userMessage: .text("hi")))
        subscriptions.forEach { $0.cancel() }
        return (messages, text, errors)
    }

    private let createSurface: JsonMap = [
        "version": "1.0",
        "createSurface": [surfaceIdKey: "main", "catalogId": basicCatalogId] as JsonMap
    ]
    private let updateComponents: JsonMap = [
        "version": "1.0",
        "updateComponents": [
            surfaceIdKey: "main",
            "components": [["id": "root", "component": "Text", "text": "Hi"]]
        ] as JsonMap
    ]

    @Test("A message list in a data part is decoded in order")
    func messageList() async {
        let result = await receive([
            makeStreamEvent(a2uiMessages: [createSurface, updateComponents], text: "Here you go")
        ])

        #expect(result.messages.count == 2)
        #expect(result.messages[0].surfaceId == "main")
        #expect(result.text == "Here you go")
        #expect(result.errors.isEmpty)
    }

    @Test("A wrapped message list is also accepted")
    func wrappedList() async {
        let event = A2ASendStreamMessageSuccessResponse(
            result: A2AMessage(
                parts: [
                    A2ADataPart(
                        data: ["messages": [createSurface]] as JsonMap,
                        metadata: ["mimeType": A2UIProtocol.mimeType]
                    )
                ]
            ),
            id: 1
        )
        let result = await receive([event])

        #expect(result.messages.count == 1)
    }

    @Test("Data parts without a MIME type are inspected before use")
    func missingMimeType() async {
        let a2ui = await receive([makeStreamEvent(a2uiMessages: [createSurface], mimeType: nil)])
        #expect(a2ui.messages.count == 1)

        let unrelated = A2ASendStreamMessageSuccessResponse(
            result: A2AMessage(parts: [A2ADataPart(data: ["somethingElse": true] as JsonMap)]),
            id: 1
        )
        let other = await receive([unrelated])
        #expect(other.messages.isEmpty)
        #expect(other.errors.isEmpty)
    }

    @Test("Legacy A2UI MIME types are still accepted")
    func legacyMimeType() async {
        let result = await receive([
            makeStreamEvent(a2uiMessages: [createSurface], mimeType: "application/json+a2ui")
        ])
        #expect(result.messages.count == 1)
    }

    @Test("A malformed message is reported and the rest still applies")
    func partialFailure() async {
        let result = await receive([
            makeStreamEvent(a2uiMessages: [["version": "1.0", "bogus": [:] as JsonMap] as JsonMap, updateComponents])
        ])

        #expect(result.messages.count == 1)
        #expect(result.errors.count == 1)
    }

    @Test("Messages inside task status updates are processed")
    func taskStatusUpdates() async {
        let message = A2AMessage(
            parts: [A2ADataPart(data: [createSurface], metadata: ["mimeType": A2UIProtocol.mimeType])]
        )
        let events: [A2ASendStreamMessageResponse] = [
            A2ASendStreamMessageSuccessResponse(result: A2ATask(id: "t", contextId: "c"), id: 1),
            A2ASendStreamMessageSuccessResponse(
                result: A2ATaskStatusUpdateEvent(
                    taskId: "t",
                    contextId: "c",
                    status: A2ATaskStatus(message: message),
                    end: true
                ),
                id: 1
            )
        ]
        let result = await receive(events)

        #expect(result.messages.count == 1)
    }

    @Test("A JSON-RPC error event is surfaced on the error stream")
    func rpcError() async {
        let result = await receive([
            A2AJSONRPCErrorResponseSSM(error: A2AError(rpcErrorCode: -32603, message: "boom"), id: 1)
        ])

        #expect(result.messages.isEmpty)
        #expect(result.errors.count == 1)
        #expect(A2UIErrorFormatter.describe(result.errors[0]).contains("boom"))
    }
}

@MainActor
@Suite("A2A agent cards")
struct AgentCardTests {
    @Test("A2UI capabilities are read from the extension params")
    func a2uiCapabilities() async throws {
        let connector = A2UIAgentConnector(url: URL(string: "https://example.com")!, client: MockA2AClient())
        let card = try await connector.agentCard()
        let capabilities = try #require(card.a2uiCapabilities)

        #expect(capabilities.supportedCatalogIds == [basicCatalogId])
        #expect(capabilities.acceptsInlineCatalogs)
    }

    @Test("A card without the A2UI extension reports no capabilities")
    func withoutExtension() async throws {
        let client = MockA2AClient(
            card: A2AAgentCard(
                name: "Plain",
                description: "",
                version: "1",
                url: "https://example.com/",
                capabilities: A2AAgentCapabilities(streaming: true)
            )
        )
        let connector = A2UIAgentConnector(url: URL(string: "https://example.com")!, client: client)

        #expect(try await connector.agentCard().a2uiCapabilities == nil)
    }

    @Test("Agent cards round-trip through JSON")
    func parsing() throws {
        let json: JsonMap = [
            "name": "Agent",
            "description": "d",
            "version": "1.0",
            "url": "https://example.com/",
            "capabilities": [
                "streaming": true,
                "extensions": [
                    [
                        "uri": A2UIProtocol.a2aExtensionUri,
                        "required": false,
                        "params": ["supportedCatalogIds": [basicCatalogId]] as JsonMap
                    ] as JsonMap
                ]
            ] as JsonMap
        ]
        let card = try A2AAgentCard.fromJson(json)

        #expect(card.capabilities?.extensions.count == 1)
        #expect(card.a2uiCapabilities?.supportedCatalogIds == [basicCatalogId])
        #expect(throws: (any Error).self) {
            try A2AAgentCard.fromJson(["name": "no url"])
        }
    }
}

@MainActor
@Suite("Content generator")
struct ContentGeneratorTests {
    @Test("Requests without content are skipped")
    func emptyRequests() async {
        let client = MockA2AClient()
        let connector = A2UIAgentConnector(url: URL(string: "https://example.com")!, client: client)
        let generator = A2UIContentGenerator(serverUrl: URL(string: "https://example.com")!, connector: connector)

        await generator.send(GenerationRequest())
        #expect(client.sentPayloads.isEmpty)

        await generator.send(GenerationRequest(userMessage: .text("hi")))
        #expect(client.sentPayloads.count == 1)
    }

    @Test("Agent messages and text are republished to subscribers")
    func republishing() async {
        let event = makeStreamEvent(
            a2uiMessages: [["version": "1.0", "createSurface": [surfaceIdKey: "main"] as JsonMap] as JsonMap],
            text: "hello"
        )
        let connector = A2UIAgentConnector(
            url: URL(string: "https://example.com")!,
            client: MockA2AClient(events: [event])
        )
        let generator = A2UIContentGenerator(serverUrl: URL(string: "https://example.com")!, connector: connector)

        var messages: [A2UIMessage] = []
        var texts: [String] = []
        let subscriptions = [
            generator.messages.sink { messages.append($0) },
            generator.textResponses.sink { texts.append($0) }
        ]

        await generator.send(GenerationRequest(userMessage: .text("hi")))
        await waitUntil("the message to be delivered on the main queue") { !messages.isEmpty && !texts.isEmpty }
        subscriptions.forEach { $0.cancel() }

        #expect(messages.count == 1)
        #expect(texts == ["hello"])
        #expect(generator.isProcessing.value == false)
    }
}
