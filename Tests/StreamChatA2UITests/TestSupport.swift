//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing

// MARK: - Catalog helpers

/// Records the render contexts a catalog produced, so tests can inspect them.
@MainActor
final class RenderRecorder {
    private(set) var contexts: [String: ComponentRenderContext] = [:]

    func record(_ context: ComponentRenderContext) {
        contexts[context.id] = context
    }

    func context(_ id: String) -> ComponentRenderContext? {
        contexts[id]
    }
}

/// Builds a catalog whose components record their render context.
///
/// Rendering a SwiftUI view cannot be inspected directly in a unit test, so the
/// tests assert on the context each component received instead.
@MainActor
enum TestCatalog {
    static let catalogId = "test.a2ui:catalog"

    static func make(recorder: RenderRecorder, extraComponents: [ComponentDefinition] = []) -> Catalog {
        let types = ["Column", "Row", "Text", "Card", "List", "Button", "TextField", "Widget"]
        var components = types.map { name in
            ComponentDefinition(
                name: name,
                properties: ["children": JsonSchema.children(), "text": JsonSchema.dynamicString()]
            ) { context in
                recorder.record(context)
                for child in context.resolvedChildren() {
                    _ = context.childView(child)
                }
                if let childId = context.childId() {
                    _ = context.childView(childId)
                }
                return AnyView(EmptyView())
            }
        }
        components.append(
            ComponentDefinition(name: "MenuItem", allowedParents: ["Menu"]) { context in
                recorder.record(context)
                return AnyView(EmptyView())
            }
        )
        components.append(
            ComponentDefinition(name: "Menu", allowedChildren: ["MenuItem"]) { context in
                recorder.record(context)
                for child in context.resolvedChildren() {
                    _ = context.childView(child)
                }
                return AnyView(EmptyView())
            }
        )
        components.append(
            ComponentDefinition(name: "RootOnly", allowedParents: ["Surface"]) { context in
                recorder.record(context)
                return AnyView(EmptyView())
            }
        )
        components.append(contentsOf: extraComponents)

        return Catalog(
            catalogId: catalogId,
            instructions: "Test catalog.",
            components: components,
            functions: [echoFunction, agentOnlyFunction, failingFunction] + BasicCatalog.functions
        )
    }

    /// A renderer function that returns its `value` argument unchanged.
    static let echoFunction = FunctionDefinition(
        name: "echo",
        description: "Returns the value it is given.",
        arguments: JsonSchema.object(properties: ["value": JsonSchema.dynamicValue()], required: ["value"]),
        returnType: .any
    ) { invocation in
        invocation.value("value")
    }

    /// A function only the agent may invoke.
    static let agentOnlyFunction = FunctionDefinition(
        name: "agentOnly",
        description: "Only callable by the agent.",
        arguments: JsonSchema.object(properties: ["value": JsonSchema.dynamicValue()]),
        returnType: .string,
        allowedCallers: .agentOnly
    ) { invocation in
        "agent:\(invocation.string("value") ?? "")"
    }

    /// A function that always fails, for error path tests.
    static let failingFunction = FunctionDefinition(
        name: "boom",
        description: "Always throws.",
        returnType: .void,
        allowedCallers: .rendererOrAgent
    ) { _ in
        throw A2UIFunctionError.unavailable("boom", reason: "test failure")
    }
}

/// Deterministic renderer services for tests.
enum TestServices {
    /// A fixed instant used by every time-dependent test.
    static let referenceDate = Date(timeIntervalSince1970: 1_767_225_600) // 2026-01-01T00:00:00Z

    static func make(openedUrls: OpenedUrls? = nil) -> RendererServices {
        RendererServices(
            openUrl: { url in openedUrls?.append(url) },
            now: { referenceDate },
            locale: Locale(identifier: "en_US"),
            timeZone: TimeZone(identifier: "UTC") ?? .current
        )
    }
}

/// Collects the URLs a test opened.
@MainActor
final class OpenedUrls {
    private(set) var urls: [URL] = []

    func append(_ url: URL) {
        urls.append(url)
    }
}

// MARK: - Evaluation helpers

/// Builds an evaluator over a data model for expression tests.
@MainActor
func makeEvaluator(
    data: JsonMap = [:],
    catalogs: [Catalog]? = nil,
    surfaceCatalogId: String? = TestCatalog.catalogId,
    services: RendererServices = TestServices.make(),
    router: RemoteFunctionRouter? = nil
) -> (evaluator: ExpressionEvaluator, model: DataModel) {
    let model = DataModel(data)
    let evaluator = ExpressionEvaluator(
        catalogs: CatalogRegistry(catalogs: catalogs ?? [TestCatalog.make(recorder: RenderRecorder())]),
        surfaceId: "surface",
        surfaceCatalogId: surfaceCatalogId,
        services: services,
        remoteRouter: router
    )
    return (evaluator, model)
}

/// A router that records agent-routed calls and answers from a fixed table.
@MainActor
final class StubRemoteRouter: RemoteFunctionRouter {
    var answers: [String: any Sendable] = [:]
    private(set) var calls: [(name: String, arguments: [String: any Sendable])] = []
    private(set) var errors: [RendererError] = []

    func agentFunctionValue(
        for name: String,
        catalogId: String?,
        arguments: [String: any Sendable],
        surfaceId: String,
        userActivated: Bool
    ) throws -> (any Sendable)? {
        calls.append((name, arguments))
        return answers[name]
    }

    func report(_ error: RendererError) {
        errors.append(error)
    }
}

// MARK: - Assertions

/// Decodes a JSON string into an A2UI message, failing the test on error.
@MainActor
func decodeMessage(_ json: String) throws -> A2UIMessage {
    guard let map = Json.decodeMap(json) else {
        throw A2UIDecodingError.unknownMessageType([])
    }
    return try A2UIMessageDecoder.decode(map)
}

// MARK: - Async helpers

/// Waits until a condition holds, or fails the test after `timeout` seconds.
///
/// Used for the parts of the pipeline that hop through the main queue, such as
/// the conversation coalescing renderer events into one request.
@MainActor
func waitUntil(
    _ description: String,
    timeout: TimeInterval = 10,
    condition: @MainActor () -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    let deadline = Date().addingTimeInterval(timeout)
    // Checks once more after the deadline: on a busy main actor the awaited work
    // and this loop may resume in the same turn, past the deadline.
    while !condition() {
        guard Date() < deadline else {
            Issue.record("Timed out waiting for \(description)", sourceLocation: sourceLocation)
            return
        }
        try? await Task.sleep(nanoseconds: 5_000_000)
    }
}
