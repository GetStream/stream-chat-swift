//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Applies A2UI messages to renderer state and produces the events to send back.
///
/// The processor is the heart of the renderer: it owns one ``SurfaceViewModel``
/// per surface, applies `createSurface`, `updateComponents`, `updateDataModel`
/// and `deleteSurface` messages, executes agent-initiated renderer function
/// calls, and routes function calls the renderer cannot resolve locally to the
/// agent.
///
/// All members must be used from the main thread; the transport delivers
/// messages there.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class A2UIMessageProcessor: A2UIHost, RemoteFunctionRouter {
    /// The catalogs this renderer supports.
    let catalogs: CatalogRegistry

    /// Host capabilities passed to components and functions.
    let services: RendererServices

    /// How long a function call routed to the agent may stay unanswered.
    let agentFunctionTimeout: TimeInterval

    private var surfaces: [String: SurfaceViewModel] = [:]
    private var surfaceOrder: [String] = []
    private let surfaceUpdatesSubject = PassthroughSubject<A2UIUpdate, Never>()
    private let rendererMessagesSubject = PassthroughSubject<RendererMessage, Never>()
    private var remoteCalls: [RemoteCallKey: RemoteCallState] = [:]
    private var remoteCallIds: [String: RemoteCallKey] = [:]
    private var reportedErrors: Set<String> = []
    private var callIdCounter = 0

    /// Creates a processor for the given catalogs.
    ///
    /// Pass `defaultCatalogId` to keep rendering surfaces from agents that
    /// omit `catalogId`; without it, such surfaces fail to resolve, as the
    /// specification requires.
    init(
        catalogs: [Catalog],
        defaultCatalogId: String? = nil,
        services: RendererServices = .default,
        agentFunctionTimeout: TimeInterval = 30
    ) {
        self.catalogs = CatalogRegistry(catalogs: catalogs, defaultCatalogId: defaultCatalogId)
        self.services = services
        self.agentFunctionTimeout = agentFunctionTimeout
    }

    // MARK: - Streams

    /// A stream of surface lifecycle changes.
    var surfaceUpdates: AnyPublisher<A2UIUpdate, Never> {
        surfaceUpdatesSubject.eraseToAnyPublisher()
    }

    /// A stream of messages that must be delivered to the agent.
    ///
    /// Includes user actions, renderer function responses, renderer-initiated
    /// agent function calls and renderer errors.
    var rendererMessages: AnyPublisher<RendererMessage, Never> {
        rendererMessagesSubject.eraseToAnyPublisher()
    }

    /// A stream of user actions, for hosts that only care about interactions.
    var actions: AnyPublisher<RendererAction, Never> {
        rendererMessagesSubject
            .compactMap { message in
                guard case let .action(action) = message else { return nil }
                return action
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Surfaces

    /// The ids of all live surfaces, in creation order.
    var surfaceIds: [String] {
        surfaceOrder.filter { surfaces[$0]?.definition != nil }
    }

    /// Returns the observable state of a surface, creating it if needed.
    /// Views may bind to a surface before the agent creates it.
    func surfaceViewModel(_ surfaceId: String) -> SurfaceViewModel {
        let viewModel = surfaces[surfaceId] ?? SurfaceViewModel(surfaceId: surfaceId)
        surfaces[surfaceId] = viewModel
        if !surfaceOrder.contains(surfaceId) {
            surfaceOrder.append(surfaceId)
        }
        return viewModel
    }

    /// The view model of a surface that exists, without making one.
    func existingSurfaceViewModel(_ surfaceId: String) -> SurfaceViewModel? {
        surfaceOrder.contains(surfaceId) ? surfaces[surfaceId] : nil
    }

    /// The data model of a surface, creating the surface state if needed.
    func dataModel(for surfaceId: String) -> DataModel {
        surfaceViewModel(surfaceId).dataModel
    }

    /// Removes every surface and its data.
    /// Emits removal updates unless `emitUpdates` is `false`.
    func clearSurfaces(emitUpdates: Bool = true) {
        let ids = surfaceOrder
        // Views keep the view model they were made with, so it is reset rather than replaced.
        for viewModel in surfaces.values {
            viewModel.reset()
        }
        surfaceOrder.removeAll()
        remoteCalls.removeAll()
        remoteCallIds.removeAll()
        reportedErrors.removeAll()
        guard emitUpdates else { return }
        for surfaceId in ids {
            surfaceUpdatesSubject.send(SurfaceRemoved(surfaceId: surfaceId))
        }
    }

    // MARK: - Message handling

    /// Applies an A2UI message to renderer state.
    ///
    /// Messages targeting an unknown surface are reported to the agent instead
    /// of being silently dropped, which is what lets an agent recover.
    func handle(_ message: A2UIMessage) {
        switch message {
        case let .createSurface(message):
            createSurface(message)
        case let .updateComponents(message):
            updateComponents(message)
        case let .updateDataModel(message):
            updateDataModel(message)
        case let .deleteSurface(message):
            deleteSurface(message)
        case let .callRendererFunction(message):
            callRendererFunction(message)
        case let .agentFunctionResponse(response):
            resolveAgentFunction(response)
        }
    }

    /// Applies a list of messages in order.
    ///
    /// A failing message does not stop the rest of the list, matching the A2A
    /// binding's processing rules.
    func handle(_ messages: [A2UIMessage]) {
        for message in messages {
            handle(message)
        }
    }

    /// Decodes and applies a wire message.
    ///
    /// A message that fails to decode is reported to the agent, so the agent
    /// can correct it: a malformed `callRendererFunction` is answered with an
    /// `INVALID_FUNCTION_CALL` error, anything else with `VALIDATION_FAILED`.
    func handle(json: JsonMap) {
        do {
            handle(try A2UIMessageDecoder.decode(json))
        } catch {
            a2uiLogger.warning("Could not decode an A2UI message: \(A2UIErrorFormatter.describe(error))")
            send(.error(A2UIMessageDecoder.rendererError(for: error, in: json)))
        }
    }

    private func createSurface(_ message: CreateSurfaceMessage) {
        if surfaces[message.surfaceId]?.definition != nil {
            report(
                RendererError(
                    code: RendererError.Code.integrityError,
                    message: "Surface '\(message.surfaceId)' already exists. Delete it before creating it again.",
                    surfaceId: message.surfaceId
                )
            )
            return
        }
        if let catalogId = message.catalogId, catalogs.catalog(catalogId) == nil {
            report(
                RendererError(
                    code: RendererError.Code.catalogNotFound,
                    message: "Surface '\(message.surfaceId)' requested catalog '\(catalogId)', which this renderer "
                        + "does not support. Supported catalogs: \(catalogs.supportedCatalogIds.joined(separator: ", ")).",
                    surfaceId: message.surfaceId
                )
            )
        }

        let viewModel = surfaceViewModel(message.surfaceId)
        var definition = SurfaceDefinition(
            surfaceId: message.surfaceId,
            catalogId: message.catalogId,
            sendDataModel: message.sendDataModel,
            metadata: message.metadata
        )
        let components = validated(message.components, surfaceId: message.surfaceId, catalogId: message.catalogId)
        definition.merge(components)
        for error in CompositionValidator.errors(in: definition, batch: message.components, catalogs: catalogs) {
            report(error)
        }

        var dataModel = message.dataModel
        if Json.exceedsDepth(dataModel, limit: A2UIProtocol.maxNestingDepth) {
            report(
                RendererError(
                    code: RendererError.Code.recursionLimitExceeded,
                    message: "Global recursion limit exceeded: the data model nests deeper than \(A2UIProtocol.maxNestingDepth) levels.",
                    surfaceId: message.surfaceId,
                    path: "/dataModel"
                )
            )
            dataModel = nil
        }
        viewModel.create(definition: definition, dataModel: dataModel)
        a2uiLogger.debug("Created surface '\(message.surfaceId)'.")
        surfaceUpdatesSubject.send(SurfaceAdded(surfaceId: message.surfaceId, definition: definition))
    }

    private func updateComponents(_ message: UpdateComponentsMessage) {
        guard let viewModel = surfaces[message.surfaceId], let current = viewModel.definition else {
            report(
                RendererError(
                    code: RendererError.Code.integrityError,
                    message: "Cannot update components of surface '\(message.surfaceId)' because it was not created.",
                    surfaceId: message.surfaceId
                )
            )
            return
        }
        viewModel.merge(components: validated(message.components, surfaceId: message.surfaceId, catalogId: current.catalogId))
        guard let definition = viewModel.definition else { return }
        for error in CompositionValidator.errors(in: definition, batch: message.components, catalogs: catalogs) {
            report(error)
        }
        a2uiLogger.debug("Updated \(message.components.count) component(s) on surface '\(message.surfaceId)'.")
        surfaceUpdatesSubject.send(SurfaceUpdated(surfaceId: message.surfaceId, definition: definition))
    }

    /// Reports the problems of a batch of components that can be found before
    /// rendering, and returns the components to apply.
    ///
    /// A batch that repeats an id is an integrity error; only the first
    /// component with that id is applied.
    private func validated(_ components: [Component], surfaceId: String, catalogId: String?) -> [Component] {
        var seen: Set<String> = []
        var accepted: [Component] = []
        for (index, component) in components.enumerated() {
            guard seen.insert(component.id).inserted else {
                report(
                    RendererError(
                        code: RendererError.Code.integrityError,
                        message: "The component id '\(component.id)' appears more than once in one message.",
                        surfaceId: surfaceId
                    )
                )
                continue
            }
            if Json.exceedsDepth(component.properties, limit: A2UIProtocol.maxNestingDepth) {
                report(
                    RendererError(
                        code: RendererError.Code.recursionLimitExceeded,
                        message: "Global recursion limit exceeded: component '\(component.id)' nests its properties "
                            + "deeper than \(A2UIProtocol.maxNestingDepth) levels.",
                        surfaceId: surfaceId,
                        path: "/components/\(index)"
                    )
                )
                continue
            }
            if let metadata = component.metadata, let violation = ExtensionMetadata.violation(in: metadata) {
                report(
                    RendererError(
                        code: RendererError.Code.validationFailed,
                        message: violation.reason,
                        surfaceId: surfaceId,
                        path: "/components/\(index)/metadata\(violation.pointer)"
                    )
                )
                continue
            }
            if !A2UIIdentifier.isValid(component.id) {
                report(
                    RendererError(
                        code: RendererError.Code.validationFailed,
                        message: "Component id '\(component.id)' must be a valid UAX #31 identifier.",
                        surfaceId: surfaceId,
                        path: "/components/\(index)/id"
                    )
                )
            }
            for (key, value) in component.properties.sorted(by: { $0.key < $1.key }) {
                let pointer = "/components/\(index)/" + key.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1")
                for found in DynamicValue.calls(in: value, at: pointer) {
                    if let error = callError(found.call, at: found.pointer, surfaceId: surfaceId, surfaceCatalogId: catalogId) {
                        report(error)
                    }
                }
            }
            if let definition = catalogs.resolveCatalog(entityCatalogId: component.catalogId, surfaceCatalogId: catalogId)?
                .component(component.type) {
                for violation in definition.childListViolations(of: component) {
                    report(
                        RendererError(
                            code: RendererError.Code.validationFailed,
                            message: violation.message,
                            surfaceId: surfaceId,
                            path: "/components/\(index)\(violation.pointer)"
                        )
                    )
                }
            }
            if let catalog = catalogs.resolveCatalog(entityCatalogId: component.catalogId, surfaceCatalogId: catalogId),
               catalog.component(component.type) == nil {
                report(
                    RendererError(
                        code: RendererError.Code.validationFailed,
                        message: "Component type '\(component.type)' is not defined by catalog '\(catalog.catalogId)'.",
                        surfaceId: surfaceId,
                        path: "/components/\(index)/component"
                    )
                )
            }
            for (key, value) in component.properties {
                if let violation = DynamicValue.reservedKeyViolation(in: value) {
                    report(
                        RendererError(
                            code: RendererError.Code.validationFailed,
                            message: violation,
                            surfaceId: surfaceId,
                            path: "/components/\(index)/\(key)"
                        )
                    )
                } else if DynamicValue.callDepth(of: value) > A2UIProtocol.maxFunctionCallDepth {
                    report(
                        RendererError(
                            code: RendererError.Code.validationFailed,
                            message: "The functionCall depth of '\(key)' exceeds \(A2UIProtocol.maxFunctionCallDepth).",
                            surfaceId: surfaceId,
                            path: "/components/\(index)/\(key)"
                        )
                    )
                } else if let violation = DynamicValue.formatStringViolation(in: value) {
                    report(
                        RendererError(
                            code: RendererError.Code.validationFailed,
                            message: violation.message,
                            surfaceId: surfaceId,
                            path: "/components/\(index)/\(key)\(violation.pointer)"
                        )
                    )
                }
            }
            accepted.append(component)
        }
        return accepted
    }

    // A call that can't resolve its catalog, or whose literal arguments break its function's schema.
    private func callError(_ call: JsonMap, at pointer: String, surfaceId: String, surfaceCatalogId: String?) -> RendererError? {
        guard let name = call[A2UIProtocol.callKey] as? String, !name.hasPrefix(A2UIProtocol.systemFunctionPrefix) else {
            return nil
        }
        if let raw = call["catalogId"], !(raw is String) {
            return RendererError(
                code: RendererError.Code.validationFailed,
                message: "The 'catalogId' of a call to '\(name)' must be a string.",
                surfaceId: surfaceId,
                path: "\(pointer)/catalogId"
            )
        }
        let catalogId = call["catalogId"] as? String
        guard let catalog = catalogs.resolveCatalog(entityCatalogId: catalogId, surfaceCatalogId: surfaceCatalogId) else {
            return RendererError(
                code: RendererError.Code.catalogNotFound,
                message: (catalogId ?? surfaceCatalogId).map { "Catalog not found: \($0)" }
                    ?? "Function '\(name)' has no catalogId, and the surface has no default catalogId.",
                surfaceId: surfaceId,
                path: pointer
            )
        }
        guard let schema = catalog.function(name)?.argumentsSchema,
              let violation = JsonSchemaValidator.violation(
                  of: Json.map(call["args"]) ?? [:],
                  against: schema,
                  allowsDynamicValues: true
              ) else { return nil }
        return RendererError(
            code: RendererError.Code.validationFailed,
            message: "Invalid arguments for '\(name)': \(violation.message).",
            surfaceId: surfaceId,
            path: "\(pointer)/args\(violation.pointer)"
        )
    }

    private func updateDataModel(_ message: UpdateDataModelMessage) {
        guard let viewModel = surfaces[message.surfaceId], let definition = viewModel.definition else {
            report(
                RendererError(
                    code: RendererError.Code.integrityError,
                    message: "Cannot update the data model of surface '\(message.surfaceId)' because it was not created.",
                    surfaceId: message.surfaceId
                )
            )
            return
        }
        guard !Json.exceedsDepth(message.value, limit: A2UIProtocol.maxNestingDepth) else {
            report(
                RendererError(
                    code: RendererError.Code.recursionLimitExceeded,
                    message: "Global recursion limit exceeded: the value nests deeper than \(A2UIProtocol.maxNestingDepth) levels.",
                    surfaceId: message.surfaceId,
                    path: "/value"
                )
            )
            return
        }
        do {
            try viewModel.dataModel.set(message.value, at: message.path)
        } catch {
            report(
                RendererError(
                    code: RendererError.Code.dataError,
                    message: A2UIErrorFormatter.describe(error),
                    surfaceId: message.surfaceId
                )
            )
            return
        }
        a2uiLogger.debug("Updated data model of surface '\(message.surfaceId)' at '\(message.path)'.")
        surfaceUpdatesSubject.send(SurfaceUpdated(surfaceId: message.surfaceId, definition: definition))
    }

    private func deleteSurface(_ message: DeleteSurfaceMessage) {
        // Views keep the view model they were made with, so a surface created again with the same
        // id shows in it.
        guard let viewModel = surfaces[message.surfaceId], viewModel.definition != nil else { return }
        viewModel.reset()
        surfaceOrder.removeAll { $0 == message.surfaceId }
        let staleCalls = remoteCalls.keys.filter { $0.surfaceId == message.surfaceId }
        for key in staleCalls {
            remoteCalls.removeValue(forKey: key)
        }
        remoteCallIds = remoteCallIds.filter { !staleCalls.contains($0.value) }
        a2uiLogger.debug("Deleted surface '\(message.surfaceId)'.")
        surfaceUpdatesSubject.send(SurfaceRemoved(surfaceId: message.surfaceId))
    }

    // MARK: - Functions

    private func callRendererFunction(_ message: CallRendererFunctionMessage) {
        let call = message.callFunction
        func reject(_ reason: String) {
            respond(to: message, error: FunctionResponse.Failure(code: RendererError.Code.invalidFunctionCall, message: reason))
        }
        guard let catalogId = call.catalogId, let catalog = catalogs.catalog(catalogId) else {
            reject("Catalog '\(call.catalogId ?? "")' is not registered with this renderer.")
            return
        }
        guard let definition = catalog.function(call.name) else {
            reject("Function '\(call.name)' is not registered in catalog '\(catalogId)'.")
            return
        }
        guard definition.isAgentCallable else {
            reject("Function '\(call.name)' cannot be called by the agent (allowedCallers is \(definition.allowedCallers.rawValue)).")
            return
        }
        guard !definition.requiresUserActivation else {
            reject("Function '\(call.name)' requires a user gesture, which a call from the agent doesn't have.")
            return
        }
        var dataModel = DataModel()
        if let surfaceId = message.surfaceId {
            guard let surface = surfaces[surfaceId], surface.definition != nil else {
                reject("Surface '\(surfaceId)' does not exist.")
                return
            }
            dataModel = surface.dataModel
        }

        let evaluator = ExpressionEvaluator(
            catalogs: catalogs,
            surfaceId: message.surfaceId ?? "",
            surfaceCatalogId: catalogId,
            services: services
        )
        let context = DataContext(dataModel, "/")
        do {
            let arguments = try evaluator.resolveArgumentsThrowing(call.arguments, for: call.name, in: context)
            if let schema = definition.argumentsSchema,
               let violation = JsonSchemaValidator.violation(of: arguments, against: schema) {
                reject("Invalid arguments for '\(call.name)': \(violation.message).")
                return
            }
            let value = try definition.implementation(
                FunctionInvocation(
                    name: definition.name,
                    arguments: arguments,
                    context: context,
                    services: services,
                    evaluator: evaluator
                )
            )
            send(.rendererFunctionResponse(FunctionResponse(functionCallId: message.functionCallId, value: value ?? NSNull())))
        } catch {
            respond(
                to: message,
                error: FunctionResponse.Failure(
                    code: RendererError.Code.executionError,
                    message: A2UIErrorFormatter.describe(error)
                )
            )
        }
    }

    private func respond(to message: CallRendererFunctionMessage, error: FunctionResponse.Failure) {
        a2uiLogger.warning("Rejected renderer function '\(message.callFunction.name)': \(error.message)")
        send(.rendererFunctionResponse(FunctionResponse(functionCallId: message.functionCallId, error: error)))
    }

    private func resolveAgentFunction(_ response: FunctionResponse) {
        guard let key = remoteCallIds.removeValue(forKey: response.functionCallId) else {
            a2uiLogger.warning("Received a response for unknown function call '\(response.functionCallId)'.")
            return
        }
        if let error = response.error {
            a2uiLogger.error("Agent function '\(key.name)' failed: \(error.code) \(error.message)")
            remoteCalls[key] = .failed(error)
        } else {
            remoteCalls[key] = .resolved(Json.normalized(response.value))
        }
        surfaces[key.surfaceId]?.touch()
    }

    /// Returns the agent's answer for a call, dispatching it when needed.
    ///
    /// The first evaluation returns `nil` and sends a `callAgentFunction`
    /// message; once the response arrives the surface is re-rendered and the
    /// cached value is returned. A call a person's gesture starts is sent every
    /// time, as each tap asks again.
    func agentFunctionValue(
        for name: String,
        catalogId: String?,
        arguments: [String: any Sendable],
        surfaceId: String,
        userActivated: Bool = false
    ) throws -> (any Sendable)? {
        let key = RemoteCallKey(
            surfaceId: surfaceId,
            name: name,
            catalogId: catalogId,
            arguments: Json.canonicalString(arguments),
            userActivated: userActivated
        )
        if !userActivated {
            switch remoteCalls[key] {
            case let .resolved(value):
                return value
            case .pending:
                return nil
            case let .failed(failure):
                throw A2UIFunctionError.unavailable(name, reason: "\(failure.code): \(failure.message)")
            case nil:
                break
            }
        }
        callIdCounter += 1
        let callId = "\(name)-\(callIdCounter)-\(UUID().uuidString.prefix(8))"
        remoteCalls[key] = .pending(callId)
        remoteCallIds[callId] = key
        scheduleTimeout(for: callId)
        a2uiLogger.debug("Routing function '\(name)' to the agent as call '\(callId)'.")
        send(
            .callAgentFunction(
                CallAgentFunctionMessage(
                    surfaceId: surfaceId,
                    functionCallId: callId,
                    callFunction: FunctionCall(name: name, catalogId: catalogId, arguments: arguments),
                    userActivated: userActivated
                )
            )
        )
        return nil
    }

    // MARK: - Events

    /// Forwards a user action to the agent.
    func handle(_ action: RendererAction) {
        send(.action(action))
    }

    /// Reports a renderer-side error to the agent, at most once per problem.
    ///
    /// Rendering runs on every state change, so identical errors are collapsed
    /// to keep the agent's context clean.
    func report(_ error: RendererError) {
        let key = [error.code, error.message, error.surfaceId ?? "", error.path ?? ""].joined(separator: "|")
        guard reportedErrors.insert(key).inserted else { return }
        send(.error(error))
    }

    /// Emits a message for delivery to the agent.
    /// Exposed so hosts can inject synthetic events in tests.
    func send(_ message: RendererMessage) {
        rendererMessagesSubject.send(message)
    }

    // MARK: - Remote call bookkeeping

    private struct RemoteCallKey: Hashable {
        let surfaceId: String
        let name: String
        let catalogId: String?
        let arguments: String
        let userActivated: Bool
    }

    private enum RemoteCallState {
        case pending(String)
        case resolved((any Sendable)?)
        case failed(FunctionResponse.Failure)
    }

    private func scheduleTimeout(for callId: String) {
        let nanoseconds = UInt64(max(agentFunctionTimeout, 0) * 1_000_000_000)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            self?.timeOut(callId)
        }
    }

    private func timeOut(_ callId: String) {
        guard let key = remoteCallIds.removeValue(forKey: callId) else { return }
        a2uiLogger.warning("Agent function '\(key.name)' did not answer within \(agentFunctionTimeout) seconds.")
        remoteCalls[key] = .failed(
            FunctionResponse.Failure(code: RendererError.Code.timeout, message: "The agent did not answer in time.")
        )
        surfaces[key.surfaceId]?.touch()
    }
}
