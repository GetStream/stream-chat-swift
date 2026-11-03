//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing

/// The result of rendering a component list in a test.
@MainActor
private final class RenderResult {
    let recorder = RenderRecorder()
    var actions: [RendererAction] = []
    var errors: [RendererError] = []
    var model = DataModel()
}

/// Builds a renderer over a component list and renders it once.
///
/// Events dispatched later, for example by invoking an action on a recorded
/// context, are collected into the same result.
@MainActor
private func render(
    components: [Component],
    data: JsonMap = [:],
    catalogId: String? = TestCatalog.catalogId,
    services: RendererServices = TestServices.make(),
    router: RemoteFunctionRouter? = nil
) -> RenderResult {
    let result = RenderResult()
    let catalog = TestCatalog.make(recorder: result.recorder)
    var definition = SurfaceDefinition(surfaceId: "surface", catalogId: catalogId)
    definition.merge(components)

    result.model = DataModel(data)
    let evaluator = ExpressionEvaluator(
        catalogs: CatalogRegistry(catalogs: [catalog]),
        surfaceId: "surface",
        surfaceCatalogId: catalogId,
        services: services,
        remoteRouter: router
    )
    let renderer = SurfaceRenderer(
        definition: definition,
        catalogs: evaluator.catalogs,
        evaluator: evaluator,
        onAction: { [weak result] in result?.actions.append($0) },
        onError: { [weak result] in result?.errors.append($0) }
    )
    _ = renderer.rootView(dataContext: DataContext(result.model, "/"))
    return result
}

@MainActor
@Suite("Surface rendering")
struct SurfaceRendererTests {
    @Test("The tree is walked from the root through id references")
    func treeWalk() {
        let result = render(
            components: [
                Component(id: "root", type: "Column", properties: ["children": ["title", "body"]]),
                Component(id: "title", type: "Text", properties: ["text": "Hello"]),
                Component(id: "body", type: "Text", properties: ["text": ["@path": "/body"]])
            ],
            data: ["body": "World"]
        )

        #expect(result.recorder.context("root") != nil)
        #expect(result.recorder.context("title")?.string("text") == "Hello")
        #expect(result.recorder.context("body")?.string("text") == "World")
        #expect(result.errors.isEmpty)
    }

    @Test("Dangling child references are skipped without an error")
    func danglingReferences() {
        let result = render(
            components: [
                Component(id: "root", type: "Column", properties: ["children": ["missing", "title"]]),
                Component(id: "title", type: "Text", properties: ["text": "Hello"])
            ]
        )

        #expect(result.recorder.context("title") != nil)
        #expect(result.errors.isEmpty)
    }

    @Test("Template children are expanded once per item with their own scope")
    func templateChildren() throws {
        let result = render(
            components: [
                Component(id: "root", type: "List", properties: ["children": ["componentId": "row", "path": "/items"]]),
                Component(id: "row", type: "Text", properties: ["text": ["@path": "name"]])
            ],
            data: ["items": [["name": "Tea"], ["name": "Coffee"], ["name": "Juice"]]]
        )

        let root = try #require(result.recorder.context("root"))
        let children = root.resolvedChildren()
        #expect(children.count == 3)
        #expect(children.map(\.id) == ["row#0", "row#1", "row#2"])
        #expect(children[1].dataContext.itemIndex == 1)
        #expect(Json.string(children[2].dataContext.value(at: DataPath("name"))) == "Juice")
    }

    @Test("An empty collection renders no children")
    func emptyTemplate() throws {
        let result = render(
            components: [
                Component(id: "root", type: "List", properties: ["children": ["componentId": "row", "path": "/items"]]),
                Component(id: "row", type: "Text", properties: ["text": "x"])
            ],
            data: ["items": [any Sendable]()]
        )

        #expect(try #require(result.recorder.context("root")).resolvedChildren().isEmpty)
    }

    @Test("Child weights are read from the child component")
    func weights() throws {
        let result = render(
            components: [
                Component(id: "root", type: "Row", properties: ["children": ["left", "right"]]),
                Component(id: "left", type: "Text", properties: ["text": "a", "weight": 2]),
                Component(id: "right", type: "Text", properties: ["text": "b"])
            ]
        )

        let children = try #require(result.recorder.context("root")).resolvedChildren()
        #expect(children[0].weight == 2)
        #expect(children[1].weight == nil)
    }

    @Test("Unknown component types render nothing")
    func unknownComponentType() {
        // The processor reports unknown types when the message arrives, with the
        // component's position in that message, so rendering stays quiet.
        let result = render(components: [Component(id: "root", type: "Nonexistent")])

        #expect(result.errors.isEmpty)
    }

    @Test("A surface without a resolvable catalog reports an error")
    func unresolvableCatalog() {
        let result = render(
            components: [Component(id: "root", type: "Text", properties: ["text": "hi"])],
            catalogId: nil
        )

        #expect(result.errors.count == 1)
        #expect(result.recorder.context("root") == nil)
    }

    @Test("Cyclic component references stop at the depth limit")
    func cycleGuard() {
        let result = render(
            components: [
                Component(id: "root", type: "Column", properties: ["children": ["loop"]]),
                Component(id: "loop", type: "Column", properties: ["children": ["root"]])
            ]
        )

        #expect(result.errors.contains { $0.code == RendererError.Code.recursionLimitExceeded })
    }

    @Test("Composition constraints are enforced while rendering")
    func compositionConstraints() {
        let allowed = render(
            components: [
                Component(id: "root", type: "Menu", properties: ["children": ["item"]]),
                Component(id: "item", type: "MenuItem")
            ]
        )
        #expect(allowed.errors.isEmpty)
        #expect(allowed.recorder.context("item") != nil)

        let forbidden = render(
            components: [
                Component(id: "root", type: "Column", properties: ["children": ["item"]]),
                Component(id: "item", type: "MenuItem")
            ]
        )
        // The processor reports these when the components arrive; the renderer leaves them out.
        #expect(forbidden.recorder.context("item") == nil)

        let wrongChild = render(
            components: [
                Component(id: "root", type: "Menu", properties: ["children": ["text"]]),
                Component(id: "text", type: "Text", properties: ["text": "x"])
            ]
        )
        #expect(wrongChild.recorder.context("text") == nil)
    }

    @Test("A root-only component may not appear deeper in the tree")
    func rootOnlyComponent() {
        let atRoot = render(components: [Component(id: "root", type: "RootOnly")])
        #expect(atRoot.errors.isEmpty)

        let nested = render(
            components: [
                Component(id: "root", type: "Column", properties: ["children": ["nested"]]),
                Component(id: "nested", type: "RootOnly")
            ]
        )
        #expect(nested.recorder.context("nested") == nil)
    }
}

@MainActor
@Suite("Component render context")
struct ComponentRenderContextTests {
    @Test("Event actions are dispatched with a resolved context")
    func eventDispatch() throws {
        let result = render(
            components: [
                Component(
                    id: "root",
                    type: "Button",
                    properties: [
                        "child": "label",
                        "action": [
                            "event": [
                                "name": "submitOrder",
                                "userMessage": ["@call": "formatString", "args": ["value": "Order for ${/name}"]] as JsonMap,
                                "context": [
                                    "email": ["@path": "/email"],
                                    "formId": "contact",
                                    "count": 2
                                ] as JsonMap
                            ] as JsonMap
                        ] as JsonMap
                    ]
                ),
                Component(id: "label", type: "Text", properties: ["text": "Send"])
            ],
            data: ["email": "ada@example.com", "name": "Ada"]
        )

        try #require(result.recorder.context("root")).performAction()

        #expect(result.actions.count == 1)
        let action = try #require(result.actions.first)
        #expect(action.name == "submitOrder")
        #expect(action.surfaceId == "surface")
        #expect(action.sourceComponentId == "root")
        #expect(action.userMessage == "Order for Ada")
        #expect(Json.string(action.context["email"]) == "ada@example.com")
        #expect(Json.string(action.context["formId"]) == "contact")
        #expect(Json.int(action.context["count"]) == 2)
        #expect(action.timestamp == TestServices.referenceDate)
    }

    @Test("Function actions run locally")
    func functionAction() throws {
        let opened = OpenedUrls()
        let result = render(
            components: [
                Component(
                    id: "root",
                    type: "Button",
                    properties: [
                        "child": "label",
                        "action": [
                            "functionCall": ["@call": "openUrl", "args": ["url": ["@path": "/url"]]] as JsonMap
                        ] as JsonMap
                    ]
                ),
                Component(id: "label", type: "Text", properties: ["text": "Open"])
            ],
            data: ["url": "https://example.com"],
            services: TestServices.make(openedUrls: opened)
        )

        try #require(result.recorder.context("root")).performAction()
        #expect(opened.urls.map(\.absoluteString) == ["https://example.com"])
    }

    @Test("Two-way bindings write back to the data model")
    func twoWayBinding() throws {
        let result = render(
            components: [
                Component(id: "root", type: "TextField", properties: ["label": "Email", "value": ["@path": "/form/email"]])
            ],
            data: ["form": ["email": "old@example.com"] as JsonMap]
        )

        let context = try #require(result.recorder.context("root"))
        let binding = context.stringBinding()
        #expect(binding.wrappedValue == "old@example.com")

        binding.wrappedValue = "new@example.com"
        #expect(Json.string(result.model.value(at: DataPath("/form/email"))) == "new@example.com")
    }

    @Test("Bindings expose typed accessors with defaults")
    func typedBindings() throws {
        let result = render(
            components: [
                Component(
                    id: "root",
                    type: "Widget",
                    properties: [
                        "flag": ["@path": "/flag"],
                        "amount": ["@path": "/amount"],
                        "tags": ["@path": "/tags"]
                    ]
                )
            ],
            data: ["flag": true, "amount": 4.5, "tags": ["a"]]
        )

        let context = try #require(result.recorder.context("root"))
        #expect(context.boolBinding("flag").wrappedValue == true)
        #expect(context.doubleBinding("amount").wrappedValue == 4.5)
        #expect(context.stringArrayBinding("tags").wrappedValue == ["a"])
        #expect(context.doubleBinding("missing", default: 7).wrappedValue == 7)

        context.stringArrayBinding("tags").wrappedValue = ["a", "b"]
        #expect(Json.stringArray(result.model.value(at: DataPath("/tags"))) == ["a", "b"])
    }

    @Test("Writing to a literal property is ignored")
    func literalWrite() throws {
        let result = render(
            components: [Component(id: "root", type: "TextField", properties: ["label": "L", "value": "fixed"])],
            data: [:]
        )

        let context = try #require(result.recorder.context("root"))
        context.stringBinding().wrappedValue = "changed"
        #expect(result.model.snapshot.isEmpty)
    }

    @Test("Validation state is exposed to components")
    func validation() throws {
        let result = render(
            components: [
                Component(
                    id: "root",
                    type: "TextField",
                    properties: [
                        "label": "Email",
                        "value": ["@path": "/email"],
                        "checks": [
                            ["condition": ["@call": "email", "args": ["value": ["@path": "/email"]]] as JsonMap]
                        ]
                    ]
                )
            ],
            data: ["email": "not-an-email"]
        )

        let context = try #require(result.recorder.context("root"))
        #expect(!context.isValid)
        #expect(context.validationErrors == ["Please enter a valid email address (e.g. user@example.com)."])
    }

    @Test("Style hints are read as literals, ignoring bindings")
    func styleHints() throws {
        let result = render(
            components: [
                Component(id: "root", type: "Text", properties: ["text": "x", "variant": "caption"])
            ]
        )

        let context = try #require(result.recorder.context("root"))
        #expect(context.option("variant", default: "body") == "caption")
        #expect(context.option("align", default: "stretch") == "stretch")
    }
}

@MainActor
@Suite("Layout mapping")
struct LayoutMappingTests {
    @Test("Main-axis distributions map onto spacers")
    func spacers() {
        func spacers(_ justify: String) -> [Int] {
            let spacers = A2UILayout.spacersFor(justify: justify, hasWeightedChild: false)
            return [spacers.leading, spacers.between, spacers.trailing]
        }
        #expect(spacers("start") == [0, 0, 1])
        #expect(spacers("center") == [1, 0, 1])
        #expect(spacers("end") == [1, 0, 0])
        #expect(spacers("spaceBetween") == [0, 1, 0])
        #expect(spacers("spaceAround") == [1, 2, 1])
        #expect(spacers("spaceEvenly") == [1, 1, 1])
    }

    @Test("Weighted children share the free space in proportion to their weights")
    func flexSlots() {
        // 300 points, two 8-point gaps and a 40-point fixed child leave 244 for weights 1 and 3.
        #expect(A2UIFlex.slots(natural: [40, 0, 0], weights: [0, 1, 3], available: 300, spacing: 8) == [40, 61, 183])
        // Fixed children that don't fit shrink in proportion, leaving nothing for the weighted one.
        #expect(A2UIFlex.slots(natural: [200, 200, 0], weights: [0, 0, 1], available: 216, spacing: 8) == [100, 100, 0])
        // Without a known length every child keeps its natural length.
        #expect(A2UIFlex.slots(natural: [10, 20], weights: [1, 0], available: nil, spacing: 8) == [10, 20])
    }

    @Test("justify distributes the space the children leave free")
    func flexOffsets() {
        let lengths: [CGFloat] = [20, 20]
        func offsets(_ justify: String) -> [CGFloat] {
            A2UIFlex.offsets(lengths: lengths, length: 100, justify: justify, spacing: 0)
        }
        #expect(offsets("start") == [0, 20])
        #expect(offsets("end") == [60, 80])
        #expect(offsets("center") == [30, 50])
        #expect(offsets("spaceBetween") == [0, 80])
        #expect(offsets("spaceAround") == [15, 65])
        #expect(offsets("spaceEvenly") == [20, 60])
    }

    @Test("A weighted child absorbs the free space instead of a spacer")
    func weightedChildSuppressesSpacers() {
        // Without this, a spacer competes with the weighted child and starves
        // short siblings, such as the price at the end of a list row.
        for justify in ["start", "center", "end", "spaceBetween", "spaceAround", "spaceEvenly"] {
            #expect(
                A2UILayout.spacersFor(justify: justify, hasWeightedChild: true) == A2UILayout.Spacers(leading: 0, between: 0, trailing: 0),
                "justify: \(justify)"
            )
        }
    }

    @Test("Cross-axis alignments map onto SwiftUI alignments")
    func alignments() {
        #expect(A2UILayout.horizontalAlignment("center") == .center)
        #expect(A2UILayout.horizontalAlignment("end") == .trailing)
        #expect(A2UILayout.horizontalAlignment("stretch") == .leading)
        #expect(A2UILayout.verticalAlignment("center") == .center)
        #expect(A2UILayout.verticalAlignment("end") == .bottom)
        #expect(A2UILayout.verticalAlignment("start") == .top)
    }
}
