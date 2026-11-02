//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamChatA2UI
import Testing

@MainActor
@Suite("Conversation")
struct A2UIConversationTests {
    private func makeConversation(
        forwardsRendererMessages: Bool = true
    ) -> (conversation: A2UIConversation, generator: FakeContentGenerator, processor: A2UIMessageProcessor) {
        let generator = FakeContentGenerator()
        let processor = A2UIMessageProcessor(
            catalogs: [TestCatalog.make(recorder: RenderRecorder())],
            services: TestServices.make()
        )
        let conversation = A2UIConversation(
            contentGenerator: generator,
            processor: processor,
            forwardsRendererMessages: forwardsRendererMessages
        )
        return (conversation, generator, processor)
    }

    @Test("Sending a prompt records history and advertises capabilities")
    func sendPrompt() async throws {
        let (conversation, generator, _) = makeConversation()
        await conversation.send(text: "Find sushi")

        let request = try #require(generator.requests.first)
        #expect(request.userMessage?.text == "Find sushi")
        #expect(request.capabilities?.supportedCatalogIds == [TestCatalog.catalogId])
        #expect(request.dataModel?.isEmpty == true)
        #expect(conversation.conversation.value.count == 1)
        #expect((conversation.conversation.value[0] as? UserMessage)?.text == "Find sushi")
    }

    @Test("Agent messages become rendered surfaces in the conversation")
    func agentMessages() async {
        let (conversation, generator, _) = makeConversation()
        var added: [String] = []
        conversation.onSurfaceAdded = { added.append($0.surfaceId) }

        generator.messagesSubject.send(
            .createSurface(
                CreateSurfaceMessage(
                    surfaceId: "main",
                    catalogId: TestCatalog.catalogId,
                    components: [Component(id: "root", type: "Text", properties: ["text": "Hi"])]
                )
            )
        )

        #expect(added == ["main"])
        #expect(conversation.conversation.value.compactMap { $0 as? AiUiMessage }.count == 1)
    }

    @Test("Surface updates replace the surface's conversation entry")
    func surfaceUpdates() async {
        let (conversation, generator, _) = makeConversation()
        generator.messagesSubject.send(
            .createSurface(CreateSurfaceMessage(surfaceId: "main", catalogId: TestCatalog.catalogId))
        )
        generator.messagesSubject.send(
            .updateComponents(
                UpdateComponentsMessage(
                    surfaceId: "main",
                    components: [Component(id: "root", type: "Text", properties: ["text": "Hi"])]
                )
            )
        )

        let uiMessages = conversation.conversation.value.compactMap { $0 as? AiUiMessage }
        #expect(uiMessages.count == 1)
        #expect(uiMessages[0].definition.isRenderable)
    }

    @Test("A deleted surface leaves the conversation")
    func surfaceDeletion() async {
        let (conversation, generator, _) = makeConversation()
        generator.messagesSubject.send(
            .createSurface(CreateSurfaceMessage(surfaceId: "main", catalogId: TestCatalog.catalogId))
        )
        generator.messagesSubject.send(.deleteSurface(DeleteSurfaceMessage(surfaceId: "main")))

        #expect(conversation.conversation.value.compactMap { $0 as? AiUiMessage }.isEmpty)
    }

    @Test("Text responses are appended to the conversation")
    func textResponses() async {
        let (conversation, generator, _) = makeConversation()
        var received: [String] = []
        conversation.onTextResponse = { received.append($0) }

        generator.textSubject.send("Found 3 places")

        #expect(received == ["Found 3 places"])
        #expect((conversation.conversation.value.last as? AiTextMessage)?.text == "Found 3 places")
    }

    @Test("User actions are forwarded to the agent with the surface data model")
    func actionForwarding() async throws {
        let (conversation, generator, processor) = makeConversation()
        processor.handle(
            .createSurface(
                CreateSurfaceMessage(
                    surfaceId: "main",
                    catalogId: TestCatalog.catalogId,
                    sendDataModel: true,
                    components: [Component(id: "root", type: "Text", properties: ["text": "Hi"])],
                    dataModel: ["order": ["items": ["tea"]] as JsonMap]
                )
            )
        )

        var observed: RendererAction?
        conversation.onAction = { observed = $0 }
        processor.handle(
            RendererAction(
                name: "placeOrder",
                userMessage: "Place the order",
                surfaceId: "main",
                sourceComponentId: "button",
                timestamp: TestServices.referenceDate,
                context: ["items": ["tea"]]
            )
        )

        await waitUntil("the action to be forwarded") { !generator.requests.isEmpty }

        let request = try #require(generator.requests.first)
        #expect(request.userMessage == nil)
        #expect(request.rendererMessages.count == 1)
        #expect(observed?.name == "placeOrder")
        #expect(Json.stringArray(request.dataModel?.surfaces["main"]?["order"].flatMap { Json.map($0)?["items"] }) == ["tea"])
        #expect(conversation.conversation.value.compactMap { ($0 as? UiInteractionMessage)?.text } == ["Place the order"])
    }

    @Test("Events produced in the same turn are coalesced into one request")
    func coalescing() async throws {
        let (conversation, generator, processor) = makeConversation()
        defer { conversation.dispose() }
        processor.handle(
            .createSurface(CreateSurfaceMessage(surfaceId: "main", catalogId: TestCatalog.catalogId))
        )

        processor.report(RendererError(code: "A", message: "one", surfaceId: "main"))
        processor.report(RendererError(code: "B", message: "two", surfaceId: "main"))
        processor.handle(
            RendererAction(
                name: "tap",
                surfaceId: "main",
                sourceComponentId: "button",
                timestamp: TestServices.referenceDate,
                context: [:]
            )
        )

        await waitUntil("the coalesced request") { !generator.requests.isEmpty }
        #expect(generator.requests.count == 1)
        #expect(generator.requests[0].rendererMessages.count == 3)
    }

    @Test("Forwarding can be disabled so the app controls delivery")
    func manualForwarding() async throws {
        let (conversation, generator, processor) = makeConversation(forwardsRendererMessages: false)
        processor.handle(
            RendererAction(
                name: "tap",
                surfaceId: "main",
                sourceComponentId: "button",
                timestamp: TestServices.referenceDate,
                context: [:]
            )
        )

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(generator.requests.isEmpty)

        await conversation.send(
            rendererMessages: [
                .action(
                    RendererAction(
                        name: "tap",
                        surfaceId: "main",
                        sourceComponentId: "button",
                        timestamp: TestServices.referenceDate,
                        context: [:]
                    )
                )
            ]
        )
        #expect(generator.requests.count == 1)
    }

    @Test("Errors reach the app through the error callback")
    func errors() async {
        let (conversation, generator, _) = makeConversation()
        var messages: [String] = []
        conversation.onError = { messages.append($0.localizedDescription) }

        generator.errorSubject.send(ContentGeneratorError(A2AClientError.invalidResponse, context: "A2UI agent"))

        #expect(messages.count == 1)
        #expect(messages[0].contains("A2UI agent"))
    }

    @Test("Clearing surfaces removes them from the conversation")
    func clearSurfaces() async {
        let (conversation, generator, _) = makeConversation()
        generator.messagesSubject.send(
            .createSurface(CreateSurfaceMessage(surfaceId: "main", catalogId: TestCatalog.catalogId))
        )
        conversation.clearSurfaces()

        #expect(conversation.conversation.value.compactMap { $0 as? AiUiMessage }.isEmpty)
        #expect(conversation.processor.surfaceIds.isEmpty)
    }

    @Test("The host is the processor, so surfaces bind to it directly")
    func host() {
        let (conversation, _, processor) = makeConversation()
        #expect(conversation.host === processor)
    }
}

@MainActor
@Suite("Prompt builder")
struct PromptBuilderTests {
    @Test("The prompt explains the v1.0 envelope")
    func envelope() {
        let prompt = A2UIPromptBuilder.systemPrompt(catalogs: [], includeCatalogSchemas: false)

        for key in ["createSurface", "updateComponents", "updateDataModel", "deleteSurface", "callRendererFunction"] {
            #expect(prompt.contains(key), "prompt should mention \(key)")
        }
        #expect(prompt.contains("\"version\": \"1.0\""))
        #expect(prompt.contains("root"))
    }

    @Test("Catalog instructions and schemas are embedded")
    func catalogs() throws {
        let prompt = A2UIPromptBuilder.systemPrompt(catalogs: [BasicCatalog.catalog])

        #expect(prompt.contains(BasicCatalog.catalogId))
        #expect(prompt.contains("formatString"))
        let document = try #require(Json.decodeMap(A2UIPromptBuilder.catalogDocument(BasicCatalog.catalog)))
        #expect(document["catalogId"] as? String == BasicCatalog.catalogId)
    }
}
