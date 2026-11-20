//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing
@MainActor
@Suite("Bounded work on untrusted messages")
struct BoundedWorkTests {
    @Test("A template that formats others many times on each level stops early")
    func templateFanOut() {
        func formatting(_ path: String) -> String {
            String(repeating: "${formatString(value:${\(path)})}", count: 300)
        }
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(data: ["t": formatting("/u"), "u": formatting("/v"), "v": "x"], router: router)
        let call = FunctionCall(name: "formatString", arguments: ["value": ["@path": "/t"] as JsonMap])
        let started = ProcessInfo.processInfo.systemUptime

        #expect(evaluator.invoke(call, in: DataContext(model, "/")) == nil)

        #expect(ProcessInfo.processInfo.systemUptime - started < 2)
        #expect(router.errors.map(\.code) == [RendererError.Code.expressionError])
        #expect(router.errors.first?.message.contains("more than \(ExpressionEvaluator.maxInterpolations) templates") == true)
    }

    @Test("The parsed templates kept for reuse are few")
    func templateCacheIsBounded() throws {
        let (evaluator, model) = makeEvaluator()
        let context = DataContext(model, "/")
        for index in 0..<(ExpressionEvaluator.maxCachedTemplates * 2) {
            _ = try evaluator.interpolate("Item \(index)", in: context)
            #expect(evaluator.parsedTemplates.count <= ExpressionEvaluator.maxCachedTemplates)
        }

        #expect(!evaluator.parsedTemplates.isEmpty)
    }

    @Test("A container listing far more children than the limit reads only as many as could fit")
    func longChildListStopsAtLimit() throws {
        let children = Array(repeating: "c", count: 100_000)
        let renderer = makeRenderer([
            Component(id: "root", type: "Column", properties: ["children": children]),
            Component(id: "c", type: "Text", properties: ["text": "c"])
        ])
        let column = try #require(renderer.renderer.catalogs.catalog(TestCatalog.catalogId)?.component("Column"))
        let root = try #require(renderer.renderer.component("root"))

        #expect(column.children(of: root, limit: 10).map(\.pointer) == (0..<10).map { "/children/\($0)" })
        #expect(column.children(of: root).count == children.count)
        #expect(renderer.size(limit: SurfaceRenderer.maxExpandedComponents) == SurfaceRenderer.maxExpandedComponents + 1)
    }

    @Test("A size cut short by a cycle isn't reused where the component renders in full")
    func cycleDoesNotHideExpansion() {
        let renderer = makeRenderer([
            Component(id: "root", type: "Column", properties: ["children": ["a", "b"]]),
            Component(id: "a", type: "Column", properties: ["children": ["b"] + Array(repeating: "c", count: 100)]),
            Component(id: "b", type: "Column", properties: ["children": Array(repeating: "a", count: 100)]),
            Component(id: "c", type: "Text", properties: ["text": "c"])
        ])

        #expect(renderer.size(limit: 5000) > 5000)
    }

    @Test("A template counts its child once for each item")
    func templatesCountEachItem() {
        let items = Array(repeating: ["x": 1] as JsonMap, count: 100) as JsonArray
        let list = makeRenderer(
            [
                Component(id: "root", type: "Column", properties: ["children": ["componentId": "a", "path": "/items"] as JsonMap]),
                Component(id: "a", type: "Text", properties: ["text": "a"])
            ],
            data: ["items": items]
        )
        #expect(list.size(limit: 5000) == 101)

        let nested = makeRenderer(
            [
                Component(id: "root", type: "Column", properties: ["children": ["componentId": "a", "path": "/items"] as JsonMap]),
                Component(id: "a", type: "Column", properties: ["children": ["componentId": "b", "path": "/items"] as JsonMap]),
                Component(id: "b", type: "Text", properties: ["text": "b"])
            ],
            data: ["items": items]
        )
        #expect(nested.size(limit: 5000) > 5000)
    }

    @Test("A template over a collection far larger than the limit stops at the limit")
    func hugeTemplateStopsAtLimit() {
        let renderer = makeRenderer(
            [
                Component(id: "root", type: "Column", properties: ["children": ["componentId": "group", "path": "/items"] as JsonMap]),
                Component(id: "group", type: "Column", properties: ["children": ["componentId": "row", "path": "/items"] as JsonMap]),
                Component(id: "row", type: "Text", properties: ["text": "row"])
            ],
            data: ["items": Self.hugeCollection()]
        )
        let started = ProcessInfo.processInfo.systemUptime

        #expect(renderer.size(limit: SurfaceRenderer.maxExpandedComponents) == SurfaceRenderer.maxExpandedComponents + 1)
        _ = renderer.renderer.rootView(dataContext: DataContext(renderer.model, "/"))

        #expect(ProcessInfo.processInfo.systemUptime - started < 2)
        #expect(renderer.errors.errors.map(\.code) == [RendererError.Code.recursionLimitExceeded])
        #expect(renderer.recorder.context("root") == nil)
    }

    @Test("A template whose child hasn't arrived yet walks none of its items")
    func hugeTemplateOfMissingChild() throws {
        let groups = Array(repeating: ["x": 1] as JsonMap, count: 2000) as JsonArray
        let renderer = makeRenderer(
            [
                Component(id: "root", type: "Column", properties: ["children": ["componentId": "group", "path": "/groups"] as JsonMap]),
                Component(id: "group", type: "Column", properties: ["children": ["componentId": "row", "path": "/items"] as JsonMap])
            ],
            data: ["groups": groups, "items": Self.hugeCollection()]
        )
        let started = ProcessInfo.processInfo.systemUptime

        // The root, then each group and its template, which counts once.
        #expect(renderer.size(limit: SurfaceRenderer.maxExpandedComponents) == 1 + 2000 * 2)
        _ = renderer.renderer.rootView(dataContext: DataContext(renderer.model, "/"))
        let group = try #require(renderer.recorder.context("group"))
        #expect(group.resolvedChildren().isEmpty)

        #expect(ProcessInfo.processInfo.systemUptime - started < 2)
        #expect(renderer.errors.count == 0)
    }

    @Test("A template whose child type is unknown doesn't hide the rest of the surface")
    func templateOfUnknownTypeDoesNotCount() throws {
        let items = Array(repeating: ["x": 1] as JsonMap, count: SurfaceRenderer.maxExpandedComponents) as JsonArray
        let renderer = makeRenderer(
            [
                Component(id: "root", type: "Column", properties: ["children": ["status", "list"]]),
                Component(id: "status", type: "Text", properties: ["text": "Ready"]),
                Component(id: "list", type: "List", properties: ["children": ["componentId": "row", "path": "/items"] as JsonMap]),
                Component(id: "row", type: "Nonexistent")
            ],
            data: ["items": items]
        )

        #expect(renderer.size(limit: SurfaceRenderer.maxExpandedComponents) == 4)
        _ = renderer.renderer.rootView(dataContext: DataContext(renderer.model, "/"))
        #expect(renderer.recorder.context("status") != nil)
        #expect(try #require(renderer.recorder.context("list")).resolvedChildren().isEmpty)
    }

    private static func hugeCollection() -> JsonArray {
        Array(repeating: 1 as any Sendable, count: 1_000_000)
    }

    private func makeRenderer(_ components: [Component], data: JsonMap = [:]) -> RenderedSurface {
        var definition = SurfaceDefinition(surfaceId: "surface", catalogId: TestCatalog.catalogId)
        definition.merge(components)
        let recorder = RenderRecorder()
        let errors = ErrorLog()
        let (evaluator, model) = makeEvaluator(data: data, catalogs: [TestCatalog.make(recorder: recorder)])
        let renderer = SurfaceRenderer(
            definition: definition,
            catalogs: evaluator.catalogs,
            evaluator: evaluator,
            onAction: { _ in },
            onError: { errors.append($0) }
        )
        return RenderedSurface(renderer: renderer, model: model, recorder: recorder, errors: errors)
    }
}

@MainActor
private struct RenderedSurface {
    let renderer: SurfaceRenderer
    let model: DataModel
    let recorder: RenderRecorder
    let errors: ErrorLog

    func size(limit: Int) -> Int {
        renderer.expandedSize(limit: limit, dataContext: DataContext(model, "/"))
    }
}
