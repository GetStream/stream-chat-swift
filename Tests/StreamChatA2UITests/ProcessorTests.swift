//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamChatA2UI
import Testing

/// Collects the events a processor emits during a test.
@MainActor
final class ProcessorHarness {
    let processor: A2UIMessageProcessor
    private(set) var updates: [A2UIUpdate] = []
    private(set) var outgoing: [RendererMessage] = []
    private var cancellables: Set<AnyCancellable> = []

    init(catalogs: [Catalog]? = nil, defaultCatalogId: String? = nil) {
        let recorder = RenderRecorder()
        processor = A2UIMessageProcessor(
            catalogs: catalogs ?? [TestCatalog.make(recorder: recorder)],
            defaultCatalogId: defaultCatalogId,
            services: TestServices.make()
        )
        processor.surfaceUpdates.sink { [weak self] in self?.updates.append($0) }.store(in: &cancellables)
        processor.rendererMessages.sink { [weak self] in self?.outgoing.append($0) }.store(in: &cancellables)
    }

    var errors: [RendererError] {
        outgoing.compactMap { message in
            guard case let .error(error) = message else { return nil }
            return error
        }
    }

    var functionResponses: [FunctionResponse] {
        outgoing.compactMap { message in
            guard case let .rendererFunctionResponse(response) = message else { return nil }
            return response
        }
    }

    var agentCalls: [CallAgentFunctionMessage] {
        outgoing.compactMap { message in
            guard case let .callAgentFunction(call) = message else { return nil }
            return call
        }
    }

    func createSurface(
        _ surfaceId: String = "main",
        catalogId: String? = TestCatalog.catalogId,
        sendDataModel: Bool = false,
        components: [Component] = [],
        dataModel: JsonMap? = nil
    ) {
        processor.handle(
            .createSurface(
                CreateSurfaceMessage(
                    surfaceId: surfaceId,
                    catalogId: catalogId,
                    sendDataModel: sendDataModel,
                    components: components,
                    dataModel: dataModel
                )
            )
        )
    }
}

@MainActor
@Suite("Message processor")
struct A2UIMessageProcessorTests {
    @Test("createSurface installs components and the initial data model")
    func createSurface() throws {
        let harness = ProcessorHarness()
        harness.createSurface(
            components: [Component(id: "root", type: "Text", properties: ["text": ["@path": "/name"]])],
            dataModel: ["name": "Ada"]
        )

        let viewModel = harness.processor.surfaceViewModel("main")
        #expect(viewModel.isRenderable)
        #expect(viewModel.definition?.catalogId == TestCatalog.catalogId)
        #expect(Json.string(viewModel.dataModel.value(at: DataPath("/name"))) == "Ada")
        #expect(harness.updates.count == 1)
        #expect(harness.updates[0] is SurfaceAdded)
        #expect(harness.processor.surfaceIds == ["main"])
        #expect(harness.errors.isEmpty)
    }

    @Test("updateComponents merges into an existing surface")
    func updateComponents() {
        let harness = ProcessorHarness()
        harness.createSurface(components: [Component(id: "root", type: "Column", properties: ["children": ["a"]])])
        harness.processor.handle(
            .updateComponents(
                UpdateComponentsMessage(
                    surfaceId: "main",
                    components: [Component(id: "a", type: "Text", properties: ["text": "A"])]
                )
            )
        )

        let definition = harness.processor.surfaceViewModel("main").definition
        #expect(definition?.components.count == 2)
        #expect(harness.updates.last is SurfaceUpdated)
    }

    @Test("Messages for an unknown surface are reported to the agent")
    func unknownSurface() {
        let harness = ProcessorHarness()
        harness.processor.handle(
            .updateComponents(UpdateComponentsMessage(surfaceId: "ghost", components: []))
        )
        harness.processor.handle(
            .updateDataModel(UpdateDataModelMessage(surfaceId: "ghost", value: 1))
        )

        #expect(harness.errors.count == 2)
        #expect(harness.errors.allSatisfy { $0.code == RendererError.Code.integrityError })
    }

    @Test("An unsupported catalog is reported when the surface is created")
    func unknownCatalog() {
        let harness = ProcessorHarness()
        harness.createSurface(catalogId: "nope:catalog")

        #expect(harness.errors.map(\.code) == [RendererError.Code.catalogNotFound])
        // The surface is still created so later messages have somewhere to go.
        #expect(harness.processor.surfaceViewModel("main").definition != nil)
    }

    @Test("A renderer default catalog satisfies surfaces without one")
    func defaultCatalog() {
        let harness = ProcessorHarness(defaultCatalogId: TestCatalog.catalogId)
        harness.createSurface(catalogId: nil)

        #expect(harness.errors.isEmpty)
    }

    @Test("updateDataModel patches, creates and deletes values")
    func updateDataModel() {
        let harness = ProcessorHarness()
        harness.createSurface(dataModel: ["user": ["name": "Ada", "temp": 1] as JsonMap])

        harness.processor.handle(
            .updateDataModel(UpdateDataModelMessage(surfaceId: "main", path: DataPath("/user/name"), value: "Grace"))
        )
        harness.processor.handle(
            .updateDataModel(UpdateDataModelMessage(surfaceId: "main", path: DataPath("/user/temp"), value: nil))
        )

        let model = harness.processor.dataModel(for: "main")
        #expect(Json.string(model.value(at: DataPath("/user/name"))) == "Grace")
        #expect(model.value(at: DataPath("/user/temp")) == nil)
        #expect(harness.updates.filter { $0 is SurfaceUpdated }.count == 2)
    }

    @Test("deleteSurface removes the surface and its data")
    func deleteSurface() {
        let harness = ProcessorHarness()
        harness.createSurface(dataModel: ["a": 1])
        harness.processor.handle(.deleteSurface(DeleteSurfaceMessage(surfaceId: "main")))

        #expect(harness.processor.surfaceIds.isEmpty)
        #expect(harness.updates.last is SurfaceRemoved)
        // A view bound to the deleted surface gets a fresh, empty view model.
        #expect(harness.processor.surfaceViewModel("main").definition == nil)
    }

    @Test("Identical errors are reported only once")
    func errorDeduplication() {
        let harness = ProcessorHarness()
        let error = RendererError(code: "X", message: "same", surfaceId: "main")
        harness.processor.report(error)
        harness.processor.report(error)
        harness.processor.report(RendererError(code: "X", message: "different", surfaceId: "main"))

        #expect(harness.errors.count == 2)
    }

    @Test("Clearing surfaces emits removals and drops state")
    func clearSurfaces() {
        let harness = ProcessorHarness()
        harness.createSurface("a")
        harness.createSurface("b")
        harness.processor.clearSurfaces()

        #expect(harness.processor.surfaceIds.isEmpty)
        #expect(harness.updates.filter { $0 is SurfaceRemoved }.count == 2)
    }
}

@MainActor
@Suite("Bidirectional function calls")
struct FunctionCallProcessingTests {
    @Test("An agent-callable function is executed and answered")
    func agentCallableFunction() throws {
        let harness = ProcessorHarness()
        harness.processor.handle(
            .callRendererFunction(
                CallRendererFunctionMessage(
                    functionCallId: "call-1",
                    callFunction: FunctionCall(
                        name: "agentOnly",
                        catalogId: TestCatalog.catalogId,
                        arguments: ["value": "hi"]
                    )
                )
            )
        )

        let response = try #require(harness.functionResponses.first)
        #expect(response.functionCallId == "call-1")
        #expect(Json.string(response.value) == "agent:hi")
    }

    @Test("A renderer-only function cannot be invoked by the agent")
    func rendererOnlyFunction() throws {
        let harness = ProcessorHarness()
        harness.processor.handle(
            .callRendererFunction(
                CallRendererFunctionMessage(
                    functionCallId: "call-2",
                    callFunction: FunctionCall(name: "echo", catalogId: TestCatalog.catalogId, arguments: ["value": 1])
                )
            )
        )

        let response = try #require(harness.functionResponses.first)
        #expect(response.functionCallId == "call-2")
        #expect(response.error?.code == RendererError.Code.invalidFunctionCall)
        #expect(harness.errors.isEmpty)
    }

    @Test("An unregistered function is rejected as an invalid call")
    func unknownFunction() throws {
        let harness = ProcessorHarness()
        harness.processor.handle(
            .callRendererFunction(
                CallRendererFunctionMessage(
                    functionCallId: "call-3",
                    callFunction: FunctionCall(name: "nope", catalogId: TestCatalog.catalogId)
                )
            )
        )

        let response = try #require(harness.functionResponses.first)
        #expect(response.functionCallId == "call-3")
        #expect(response.error?.code == RendererError.Code.invalidFunctionCall)
    }

    @Test("A failing function answers with an error payload")
    func failingFunction() throws {
        let harness = ProcessorHarness()
        harness.processor.handle(
            .callRendererFunction(
                CallRendererFunctionMessage(
                    functionCallId: "call-4",
                    callFunction: FunctionCall(name: "boom", catalogId: TestCatalog.catalogId)
                )
            )
        )

        let response = try #require(harness.functionResponses.first)
        #expect(response.error?.code == RendererError.Code.executionError)
        #expect(response.value == nil)
    }

    @Test("A call a person's gesture starts is sent every time, apart from the rendered ones")
    func userActivatedAgentCalls() throws {
        let harness = ProcessorHarness()
        harness.createSurface(components: [Component(id: "root", type: "Text", properties: ["text": "x"])])

        for _ in 0..<2 {
            _ = try harness.processor.agentFunctionValue(
                for: "addReminder", catalogId: nil, arguments: [:], surfaceId: "main", userActivated: true
            )
        }
        _ = try harness.processor.agentFunctionValue(for: "addReminder", catalogId: nil, arguments: [:], surfaceId: "main")
        _ = try harness.processor.agentFunctionValue(for: "addReminder", catalogId: nil, arguments: [:], surfaceId: "main")

        #expect(harness.agentCalls.map(\.userActivated) == [true, true, false])
    }

    @Test("Unresolved functions are routed to the agent and cached on response")
    func agentRouting() throws {
        let harness = ProcessorHarness()
        harness.createSurface(components: [Component(id: "root", type: "Text", properties: ["text": "x"])])

        let first = try harness.processor.agentFunctionValue(
            for: "deliveryEstimate",
            catalogId: nil,
            arguments: ["id": "golden"],
            surfaceId: "main"
        )
        #expect(first == nil, "the first evaluation is pending")

        let call = try #require(harness.agentCalls.first)
        #expect(call.surfaceId == "main")
        #expect(call.callFunction.name == "deliveryEstimate")

        // A second evaluation while the call is in flight must not duplicate it.
        _ = try harness.processor.agentFunctionValue(
            for: "deliveryEstimate",
            catalogId: nil,
            arguments: ["id": "golden"],
            surfaceId: "main"
        )
        #expect(harness.agentCalls.count == 1)

        let revisionBefore = harness.processor.surfaceViewModel("main").revision
        harness.processor.handle(
            .agentFunctionResponse(FunctionResponse(functionCallId: call.functionCallId, value: "25 min"))
        )

        #expect(harness.processor.surfaceViewModel("main").revision > revisionBefore)
        let resolved = try harness.processor.agentFunctionValue(
            for: "deliveryEstimate",
            catalogId: nil,
            arguments: ["id": "golden"],
            surfaceId: "main"
        )
        #expect(Json.string(resolved) == "25 min")
    }

    @Test("Different arguments produce a separate call")
    func argumentIdentity() throws {
        let harness = ProcessorHarness()
        harness.createSurface()

        _ = try harness.processor.agentFunctionValue(for: "estimate", catalogId: nil, arguments: ["id": "a"], surfaceId: "main")
        _ = try harness.processor.agentFunctionValue(for: "estimate", catalogId: nil, arguments: ["id": "b"], surfaceId: "main")

        #expect(harness.agentCalls.count == 2)
    }

    @Test("A failed agent call stops being retried")
    func failedAgentCall() throws {
        let harness = ProcessorHarness()
        harness.createSurface()

        _ = try harness.processor.agentFunctionValue(for: "estimate", catalogId: nil, arguments: [:], surfaceId: "main")
        let call = try #require(harness.agentCalls.first)
        harness.processor.handle(
            .agentFunctionResponse(
                FunctionResponse(
                    functionCallId: call.functionCallId,
                    error: FunctionResponse.Failure(code: "UNKNOWN_FUNCTION", message: "no")
                )
            )
        )

        #expect(throws: A2UIFunctionError.self) {
            try harness.processor.agentFunctionValue(for: "estimate", catalogId: nil, arguments: [:], surfaceId: "main")
        }
        #expect(harness.agentCalls.count == 1)
    }

    @Test("A response for an unknown call id is ignored")
    func unknownResponse() {
        let harness = ProcessorHarness()
        harness.processor.handle(.agentFunctionResponse(FunctionResponse(functionCallId: "ghost", value: 1)))

        #expect(harness.outgoing.isEmpty)
    }
}
