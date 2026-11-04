//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing

// The media components need AVKit, which a headless macOS test process can't load, so these
// tests run on iOS only.
#if canImport(UIKit)
import AVKit
import UIKit

/// Lays a view out in a hosting controller, so its body and its children's bodies run.
@MainActor
private func layOut(_ view: some View, width: CGFloat = 390) -> CGSize {
    let proposal = CGSize(width: width, height: 2000)
    let controller = UIHostingController(rootView: view)
    controller.view.frame = CGRect(origin: .zero, size: proposal)
    controller.view.layoutIfNeeded()
    return controller.sizeThatFits(in: proposal)
}

// Layout rounds to the screen's pixels, a third of a point on a 3x screen.
private let onePixelOfRounding: CGFloat = 1

@MainActor
@Suite("Basic catalog rendering")
struct CatalogRenderingTests {
    @Test("Every example of the basic catalog renders without reporting an error")
    func examplesRender() {
        let model = DebugCatalogModel(catalog: BasicCatalog.catalog, onAction: nil)
        var errors: [RendererError] = []
        let cancellable = model.processor.rendererMessages.sink { message in
            if case let .error(error) = message { errors.append(error) }
        }

        #expect(!model.surfaceIds.isEmpty)
        for surfaceId in model.surfaceIds {
            let size = layOut(A2UISurface(host: model.processor, surfaceId: surfaceId))
            #expect(size.width <= 390 + onePixelOfRounding, "\(surfaceId) is wider than the screen")
        }
        #expect(errors.isEmpty, "\(errors.map(\.message))")
        _ = layOut(DebugCatalogView(catalog: BasicCatalog.catalog, itemHeight: 120))
        cancellable.cancel()
    }

    @Test("Variants of every component render")
    func variantsRender() {
        let processor = A2UIMessageProcessor(catalogs: [BasicCatalog.catalog], services: TestServices.make())
        let components: [JsonMap] = [
            ["id": "root", "component": "Column", "children": ["tabs", "modal", "texts", "icons", "media", "inputs"], "justify": "spaceEvenly", "align": "center"],
            ["id": "tabs", "component": "Tabs", "tabs": [["title": "One", "child": "t1"] as JsonMap, ["title": ["@path": "/tab"] as JsonMap, "child": "t2"] as JsonMap] as JsonArray],
            ["id": "t1", "component": "Text", "text": "# Heading\n\n- item\n> quote\n\n**bold** [link](https://a.b)", "variant": "h1"],
            ["id": "t2", "component": "Text", "text": "caption", "variant": "caption"],
            ["id": "modal", "component": "Modal", "trigger": "open", "content": "t2"],
            ["id": "open", "component": "Button", "child": "t2", "variant": "borderless", "action": ["event": ["name": "open"] as JsonMap] as JsonMap],
            ["id": "texts", "component": "Row", "children": ["h2", "h3", "h4", "h5", "body"], "justify": "end", "align": "end"],
            ["id": "h2", "component": "Text", "text": "Two", "variant": "h2", "weight": 2],
            ["id": "h3", "component": "Text", "text": "Three", "variant": "h3", "weight": 1],
            ["id": "h4", "component": "Text", "text": "Four", "variant": "h4"],
            ["id": "h5", "component": "Text", "text": "Five", "variant": "h5"],
            ["id": "body", "component": "Text", "text": ["@call": "formatString", "args": ["value": "Hi ${/name}"] as JsonMap] as JsonMap],
            ["id": "icons", "component": "List", "children": ["componentId": "icon", "path": "/icons"] as JsonMap, "direction": "horizontal"],
            ["id": "icon", "component": "Icon", "name": ["@path": "name"] as JsonMap],
            ["id": "media", "component": "Card", "child": "mediaColumn"],
            ["id": "mediaColumn", "component": "Column", "children": ["avatar", "header", "video", "audio", "divider"]],
            ["id": "avatar", "component": "Image", "url": "https://example.com/a.png", "variant": "avatar", "fit": "contain"],
            ["id": "header", "component": "Image", "url": "asset-name", "variant": "header", "fit": "none"],
            ["id": "video", "component": "Video", "url": "https://example.com/v.mp4", "posterUrl": "https://example.com/p.png"],
            ["id": "audio", "component": "AudioPlayer", "url": "https://example.com/a.mp3", "description": "Episode"],
            ["id": "divider", "component": "Divider", "axis": "vertical"],
            ["id": "inputs", "component": "Column", "children": ["field", "long", "number", "secret", "check", "chips", "slider", "date", "time"]],
            ["id": "field", "component": "TextField", "label": "Email", "value": ["@path": "/email"] as JsonMap, "checks": [["condition": ["@call": "email", "args": ["value": ["@path": "/email"] as JsonMap] as JsonMap] as JsonMap] as JsonMap] as JsonArray],
            ["id": "long", "component": "TextField", "label": "Notes", "value": ["@path": "/notes"] as JsonMap, "variant": "longText"],
            ["id": "number", "component": "TextField", "label": "Count", "value": ["@path": "/count"] as JsonMap, "variant": "number"],
            ["id": "secret", "component": "TextField", "label": "Password", "value": ["@path": "/password"] as JsonMap, "variant": "obscured"],
            ["id": "check", "component": "CheckBox", "label": "Agree", "value": ["@path": "/agree"] as JsonMap],
            ["id": "chips", "component": "ChoicePicker", "label": "Size", "variant": "multipleSelection", "displayStyle": "chips", "options": [["label": "S", "value": "s"] as JsonMap, ["label": "M", "value": "m"] as JsonMap] as JsonArray, "value": ["@path": "/sizes"] as JsonMap],
            ["id": "slider", "component": "Slider", "label": "Volume", "min": 0, "max": 10, "steps": 5, "value": ["@path": "/volume"] as JsonMap],
            ["id": "date", "component": "DateTimeInput", "label": "Day", "enableDate": true, "value": ["@path": "/day"] as JsonMap, "min": "2026-01-01", "max": "2026-12-31"],
            ["id": "time", "component": "DateTimeInput", "label": "Time", "enableTime": true, "enableDate": false, "value": ["@path": "/time"] as JsonMap]
        ]
        processor.handle(
            .createSurface(
                CreateSurfaceMessage(
                    surfaceId: "main",
                    catalogId: BasicCatalog.catalogId,
                    components: components.compactMap { Component.fromJson($0) },
                    dataModel: [
                        "tab": "Two", "name": "Ada", "email": "ada@", "count": 3, "agree": true,
                        "sizes": ["m"], "volume": 4, "day": "2026-05-04", "time": "10:30",
                        "icons": [["name": "star"] as JsonMap, ["name": "unknown_icon"] as JsonMap] as JsonArray
                    ]
                )
            )
        )

        #expect(layOut(A2UISurface(host: processor, surfaceId: "main")).width <= 390 + onePixelOfRounding)
        #expect(A2UIIcon.allNames.contains("star"))
        #expect(A2UIIcon.allCases.allSatisfy { !$0.systemName.isEmpty })
        #expect(A2UIIcon.systemName(for: "unknown_icon") == "questionmark.circle")
    }

    @Test("Weighted children of a Row share its free space in proportion to their weights")
    func weights() throws {
        let probes = SizeProbes()
        let processor = probes.processor([
            ["id": "root", "component": "Row", "children": ["one", "three"]],
            ["id": "one", "component": "Probe", "weight": 1],
            ["id": "three", "component": "Probe", "weight": 3]
        ])

        _ = try host(A2UISurface(host: processor, surfaceId: "main"))

        let one = try #require(probes.sizes["one"]?.width)
        let three = try #require(probes.sizes["three"]?.width)
        #expect(abs(one - (390 - A2UILayout.spacing) / 4) <= onePixelOfRounding)
        #expect(abs(three - 3 * one) <= onePixelOfRounding * 3)
    }

    @Test("align: stretch gives every child of a Row the Row's height")
    func rowStretch() throws {
        let probes = SizeProbes()
        let processor = probes.processor([
            ["id": "root", "component": "Column", "children": ["row"]],
            ["id": "row", "component": "Row", "children": ["tall", "short"]],
            ["id": "tall", "component": "Probe", "height": 100],
            ["id": "short", "component": "Probe"]
        ])

        _ = try host(A2UISurface(host: processor, surfaceId: "main"))

        #expect(probes.sizes["tall"]?.height == 100)
        #expect(probes.sizes["short"]?.height == 100)
    }

    @Test("A live component announces its changes, assertively or politely")
    func liveAnnouncements() async throws {
        let announcements = Announcements()
        let services = RendererServices(locale: Locale(identifier: "en_US"), announce: { text, live in
            announcements.items.append("\(live.rawValue): \(text)")
        })
        let processor = A2UIMessageProcessor(catalogs: [BasicCatalog.catalog], services: services)
        processor.handle(json: ["version": "1.0", "createSurface": [
            "surfaceId": "main", "catalogId": BasicCatalog.catalogId, "dataModel": ["status": "Active"] as JsonMap,
            "components": [
                ["id": "root", "component": "Column", "children": ["status", "alert"]] as JsonMap,
                ["id": "status", "component": "Text", "text": ["@path": "/status"] as JsonMap, "accessibility": ["live": "polite"] as JsonMap] as JsonMap,
                ["id": "alert", "component": "Text", "text": "Alert", "accessibility": [
                    "live": "assertive", "label": ["@call": "formatString", "args": ["value": "Status is ${/status}"] as JsonMap] as JsonMap
                ] as JsonMap] as JsonMap
            ] as JsonArray
        ] as JsonMap])
        let window = try host(A2UISurface(host: processor, surfaceId: "main"))

        processor.handle(json: ["version": "1.0", "updateDataModel": ["surfaceId": "main", "path": "/status", "value": "Offline"] as JsonMap])
        try await settle(window)

        #expect(announcements.items.sorted() == ["assertive: Status is Offline", "polite: Offline"])
    }

    @Test("A Modal's trigger can open it from its own action, as a Button does under VoiceOver")
    func modalPresenter() async throws {
        // SwiftUI builds no accessibility tree in unit tests, so a trigger that calls the presenter
        // the Modal hands its subtree stands in for a Button activated by VoiceOver.
        let opener = ComponentDefinition(name: "Opener") { _ in AnyView(ModalOpener()) }
        let processor = A2UIMessageProcessor(
            catalogs: [BasicCatalog.catalog.adding(components: [opener])],
            services: TestServices.make()
        )
        processor.handle(json: ["version": "1.0", "createSurface": [
            "surfaceId": "main", "catalogId": BasicCatalog.catalogId,
            "components": [
                ["id": "root", "component": "Modal", "trigger": "open", "content": "details"] as JsonMap,
                ["id": "open", "component": "Opener"] as JsonMap,
                ["id": "details", "component": "Text", "text": "More"] as JsonMap
            ] as JsonArray
        ] as JsonMap])

        let window = try host(A2UISurface(host: processor, surfaceId: "main"))
        try await settle(window)

        #expect(window.rootViewController?.presentedViewController != nil)
    }

    @Test("An image the agent labels is not decorative")
    func labeledImage() {
        #expect(A2UIImageView.isDecorative(description: nil, label: .missing))
        #expect(!A2UIImageView.isDecorative(description: nil, label: .literal("Company logo")))
        #expect(!A2UIImageView.isDecorative(description: "A logo", label: .missing))
    }

    @Test("A clip loads only once it plays, and lets go of its player when its URL changes or it leaves")
    func mediaPlayer() throws {
        let model = A2UIMediaPlayerModel()
        let first = try #require(URL(string: "https://example.com/a.mp4"))
        model.load(first)
        #expect(model.player == nil, "nothing loads before the person plays it")

        model.play()
        let player = try #require(model.player)
        model.load(first)
        #expect(model.player === player)

        model.load(URL(string: "https://example.com/b.mp4"))
        #expect(model.player == nil)
        model.play()
        #expect((model.player?.currentItem?.asset as? AVURLAsset)?.url.lastPathComponent == "b.mp4")

        model.release()
        #expect(model.player == nil)
        #expect(model.url?.lastPathComponent == "b.mp4", "it plays again from the same URL")
    }

    @Test("Media loads only from web links by default")
    func mediaURLs() throws {
        let services = RendererServices()
        for link in ["https://example.com/a.png", "HTTP://example.com/a.png"] {
            let url = try #require(URL(string: link))
            #expect(services.mediaURL(url) != nil, "\(link)")
        }
        for link in ["file:///etc/hosts", "data:image/png;base64,AAAA", "otherapp://image", "ftp://example.com/a.png"] {
            let url = try #require(URL(string: link))
            #expect(services.mediaURL(url) == nil, "\(link)")
        }
    }

    private func host(_ view: some View) throws -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        return window
    }

    private func settle(_ window: UIWindow) async throws {
        for _ in 0..<5 {
            try await Task.sleep(nanoseconds: 100_000_000)
            window.layoutIfNeeded()
        }
    }
}

private struct ModalOpener: View {
    @Environment(\.a2uiModalPresenter) private var presenter

    var body: some View {
        Text("Open").onAppear { presenter?.present() }
    }
}

@MainActor
private final class Announcements {
    var items: [String] = []
}

// Records the size each `Probe` component is laid out at.
@MainActor
private final class SizeProbes {
    var sizes: [String: CGSize] = [:]

    func processor(_ components: [JsonMap]) -> A2UIMessageProcessor {
        let probe = ComponentDefinition(name: "Probe", properties: ["height": JsonSchema.number()]) { [self] context in
            let id = context.id
            let height = context.double("height")
            return AnyView(
                Color.clear
                    .frame(height: height.map { CGFloat($0) })
                    .background(GeometryReader { proxy -> Color in
                        self.sizes[id] = proxy.size
                        return Color.clear
                    })
            )
        }
        let processor = A2UIMessageProcessor(
            catalogs: [BasicCatalog.catalog.adding(components: [probe])],
            services: TestServices.make()
        )
        processor.handle(json: ["version": "1.0", "createSurface": [
            "surfaceId": "main", "catalogId": BasicCatalog.catalogId, "components": components as JsonArray
        ] as JsonMap])
        return processor
    }
}
#endif
