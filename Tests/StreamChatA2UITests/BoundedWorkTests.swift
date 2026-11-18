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
    @Test("A template that formats itself many times on each level stops early")
    func selfFormattingTemplateFanOut() throws {
        let part = "${formatString(value:${/t})}"
        let template = String(repeating: part, count: 300)
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(data: ["t": template], router: router)
        let started = ProcessInfo.processInfo.systemUptime

        _ = try evaluator.interpolate(template, in: DataContext(model, "/"))

        #expect(ProcessInfo.processInfo.systemUptime - started < 2)
        #expect(router.errors.allSatisfy { $0.code == RendererError.Code.expressionError })
    }

    @Test("A size cut short by a cycle isn't reused where the component renders in full")
    func cycleDoesNotHideExpansion() {
        let renderer = makeRenderer([
            Component(id: "root", type: "Column", properties: ["children": ["a", "b"]]),
            Component(id: "a", type: "Column", properties: ["children": ["b"] + Array(repeating: "c", count: 100)]),
            Component(id: "b", type: "Column", properties: ["children": Array(repeating: "a", count: 100)]),
            Component(id: "c", type: "Text", properties: ["text": "c"])
        ])

        #expect(renderer.renderer.expandedSize(limit: 5000, dataContext: DataContext(renderer.model, "/")) > 5000)
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
        #expect(list.renderer.expandedSize(limit: 5000, dataContext: DataContext(list.model, "/")) == 101)

        let nested = makeRenderer(
            [
                Component(id: "root", type: "Column", properties: ["children": ["componentId": "a", "path": "/items"] as JsonMap]),
                Component(id: "a", type: "Column", properties: ["children": ["componentId": "b", "path": "/items"] as JsonMap]),
                Component(id: "b", type: "Text", properties: ["text": "b"])
            ],
            data: ["items": items]
        )
        #expect(nested.renderer.expandedSize(limit: 5000, dataContext: DataContext(nested.model, "/")) > 5000)
    }

    private func makeRenderer(_ components: [Component], data: JsonMap = [:]) -> (renderer: SurfaceRenderer, model: DataModel) {
        var definition = SurfaceDefinition(surfaceId: "surface", catalogId: TestCatalog.catalogId)
        definition.merge(components)
        let (evaluator, model) = makeEvaluator(data: data)
        let renderer = SurfaceRenderer(definition: definition, catalogs: evaluator.catalogs, evaluator: evaluator, onAction: { _ in })
        return (renderer, model)
    }
}
