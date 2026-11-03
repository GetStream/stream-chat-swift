//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Measures the size a view asks for when offered a fixed width.
///
/// A component that reports a width larger than the offer would push the whole
/// surface, and the host's scroll view, wider than the screen.
@MainActor
private func measuredSize(_ view: AnyView, offeredWidth: CGFloat) -> CGSize {
    let proposal = CGSize(width: offeredWidth, height: 4000)
    #if canImport(UIKit)
    return UIHostingController(rootView: view).sizeThatFits(in: proposal)
    #elseif canImport(AppKit)
    return NSHostingController(rootView: view).sizeThatFits(in: proposal)
    #else
    return .zero
    #endif
}

/// Renders a surface built from the basic catalog, for layout measurement.
@MainActor
private func surfaceView(components: [Component], data: JsonMap = [:]) -> AnyView {
    let processor = A2UIMessageProcessor(
        catalogs: [BasicCatalog.catalog],
        services: TestServices.make()
    )
    processor.handle(
        .createSurface(
            CreateSurfaceMessage(
                surfaceId: "main",
                catalogId: BasicCatalog.catalogId,
                components: components,
                dataModel: data
            )
        )
    )
    return AnyView(A2UISurface(host: processor, surfaceId: "main"))
}

@MainActor
@Suite("Layout bounds")
struct LayoutBoundsTests {
    /// A narrow phone width, minus the padding a host typically applies.
    private let offeredWidth: CGFloat = 280

    @Test("Image variants have a footprint independent of the loaded image")
    func imageFootprint() {
        // A resizable image with `aspectRatio(.fill)` derives its width from
        // its height, so the footprint must come from the variant alone.
        let header = A2UIImageLayout(variant: "header")
        #expect(header.width == nil)
        #expect(header.height == A2UIImageLayout.headerHeight)
        #expect(header.expandsHorizontally)

        let fixedVariants: [(name: String, side: CGFloat)] = [
            ("icon", 24), ("avatar", 48), ("smallFeature", 72), ("largeFeature", 240)
        ]
        for variant in fixedVariants {
            let layout = A2UIImageLayout(variant: variant.name)
            #expect(layout.width == variant.side, "\(variant.name) width")
            #expect(layout.height == variant.side, "\(variant.name) height")
            #expect(!layout.expandsHorizontally, "\(variant.name) should not expand")
        }

        // The catalog default applies to an omitted or unknown variant.
        #expect(A2UIImageLayout(variant: "mediumFeature") == A2UIImageLayout(variant: "somethingElse"))
    }

    @Test("A header image fills the offered width without exceeding it")
    func headerImage() {
        let size = measuredSize(
            surfaceView(
                components: [
                    Component(
                        id: "root",
                        type: "Image",
                        properties: ["url": "https://example.com/hero.jpg", "variant": "header", "fit": "cover"]
                    )
                ]
            ),
            offeredWidth: offeredWidth
        )

        #expect(size.width <= offeredWidth)
        #expect(size.height == A2UIImageLayout.headerHeight)
    }

    @Test("A card with a header image and text stays inside the offered width")
    func heroCard() {
        let size = measuredSize(
            surfaceView(
                components: [
                    Component(id: "root", type: "Card", properties: ["child": "column"]),
                    Component(
                        id: "column",
                        type: "Column",
                        properties: ["children": ["photo", "title", "subtitle"], "align": "stretch"]
                    ),
                    Component(
                        id: "photo",
                        type: "Image",
                        properties: ["url": ["@path": "/imageUrl"], "variant": "header", "fit": "cover"]
                    ),
                    Component(id: "title", type: "Text", properties: ["text": "### Golden Dragon"]),
                    Component(
                        id: "subtitle",
                        type: "Text",
                        properties: ["text": "Chinese · Dim Sum · Chinatown", "variant": "caption"]
                    )
                ],
                data: ["imageUrl": "https://example.com/hero.jpg"]
            ),
            offeredWidth: offeredWidth
        )

        #expect(size.width <= offeredWidth)
    }

    @Test("A row of a thumbnail, a weighted label and a price stays in bounds")
    func lineItemRow() {
        let size = measuredSize(
            surfaceView(
                components: [
                    Component(id: "root", type: "Row", properties: ["children": ["photo", "name", "price"], "align": "center"]),
                    Component(
                        id: "photo",
                        type: "Image",
                        properties: ["url": "https://example.com/dish.jpg", "variant": "smallFeature"]
                    ),
                    Component(id: "name", type: "Text", properties: ["text": "1. Pork soup dumplings", "weight": 1]),
                    Component(
                        id: "price",
                        type: "Text",
                        properties: [
                            "text": ["@call": "formatCurrency", "args": ["value": 12.5, "currency": "USD"] as JsonMap] as JsonMap
                        ]
                    )
                ]
            ),
            offeredWidth: offeredWidth
        )

        #expect(size.width <= offeredWidth)
    }

    @Test("A form of inputs stays inside the offered width")
    func inputForm() {
        let size = measuredSize(
            surfaceView(
                components: [
                    Component(
                        id: "root",
                        type: "Column",
                        properties: [
                            "children": ["picker", "when", "address", "notes", "utensils", "actions"],
                            "align": "stretch"
                        ]
                    ),
                    Component(
                        id: "picker",
                        type: "ChoicePicker",
                        properties: [
                            "label": "How would you like it?",
                            "displayStyle": "chips",
                            "options": [
                                ["label": "Pickup", "value": "pickup"],
                                ["label": "Delivery", "value": "delivery"]
                            ],
                            "value": ["@path": "/order/type"]
                        ]
                    ),
                    Component(
                        id: "when",
                        type: "DateTimeInput",
                        properties: [
                            "label": "When",
                            "value": ["@path": "/order/when"],
                            "enableDate": true,
                            "enableTime": true
                        ]
                    ),
                    Component(
                        id: "address",
                        type: "TextField",
                        properties: ["label": "Delivery address", "value": ["@path": "/order/address"]]
                    ),
                    Component(
                        id: "notes",
                        type: "TextField",
                        properties: [
                            "label": "Notes for the kitchen",
                            "value": ["@path": "/order/notes"],
                            "variant": "longText"
                        ]
                    ),
                    Component(
                        id: "utensils",
                        type: "CheckBox",
                        properties: ["label": "Include utensils", "value": ["@path": "/order/utensils"]]
                    ),
                    Component(id: "actions", type: "Row", properties: ["children": ["submit"], "justify": "spaceBetween"]),
                    Component(
                        id: "submit",
                        type: "Button",
                        properties: [
                            "child": "submitLabel",
                            "variant": "primary",
                            "action": ["event": ["name": "placeOrder", "context": [:] as JsonMap] as JsonMap] as JsonMap
                        ]
                    ),
                    Component(id: "submitLabel", type: "Text", properties: ["text": "Place order"])
                ],
                data: ["order": ["type": ["pickup"], "when": "2026-01-01T12:00:00Z"] as JsonMap]
            ),
            offeredWidth: offeredWidth
        )

        #expect(size.width <= offeredWidth)
    }

    @Test("A long unbroken string does not widen the surface")
    func longText() {
        let size = measuredSize(
            surfaceView(
                components: [
                    Component(
                        id: "root",
                        type: "Text",
                        properties: ["text": String(repeating: "Supercalifragilistic ", count: 12)]
                    )
                ]
            ),
            offeredWidth: offeredWidth
        )

        #expect(size.width <= offeredWidth)
    }
}
