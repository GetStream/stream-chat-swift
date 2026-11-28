//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatA2UI
import SwiftUI
import Testing

@MainActor
@Suite("Button layout")
struct ButtonLayoutTests {
    private let width: CGFloat = 300

    @Test("A column ends at its last child")
    func columnEndsAtItsLastChild() {
        guard #available(iOS 16.0, macOS 13.0, *) else { return }
        let inColumn = height([
            ["id": "root", "component": "Card", "child": "column"],
            ["id": "column", "component": "Column", "children": ["button"]]
        ] + button(variant: "primary"))
        let alone = height([["id": "root", "component": "Card", "child": "button"]] + button(variant: "primary"))

        #expect(inColumn == alone)
    }

    @Test("A button is as wide as a column that stretches its children")
    func buttonFillsAStretchingColumn() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else { return }
        let measured = try #require(accentWidth([["id": "root", "component": "Column", "children": ["button"]]] + button(variant: "primary")))

        #expect(measured >= width - 2)
    }

    @Test("A button keeps the width of its title where its container doesn't stretch it")
    func buttonKeepsTheWidthOfItsTitle() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else { return }
        let start = [["id": "root", "component": "Column", "children": ["button"], "align": "start"] as JsonMap]
        let row = [["id": "root", "component": "Row", "children": ["button"]] as JsonMap]
        let card = [
            ["id": "root", "component": "Column", "children": ["card"]] as JsonMap,
            ["id": "card", "component": "Card", "child": "button"]
        ]

        for (name, container) in [("start", start), ("row", row), ("card", card)] {
            let measured = try #require(accentWidth(container + button(variant: "primary")), "\(name)")
            #expect(measured < width / 2, "\(name)")
        }
    }

    @Test("A borderless button keeps the width of its title in a stretching column")
    func borderlessButtonKeepsTheWidthOfItsTitle() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else { return }
        let measured = try #require(accentWidth([["id": "root", "component": "Column", "children": ["button"]]] + button(variant: "borderless")))

        #expect(measured < width / 2)
    }

    @Test("A button's title is in the theme's label font")
    func buttonTitleUsesTheLabelFont() {
        guard #available(iOS 16.0, macOS 13.0, *) else { return }
        var theme = A2UITheme()
        theme.body = .system(size: 40)
        theme.label = .system(size: 12)
        let button = height(button(variant: "primary", isRoot: true), theme: theme)
        let text = height([["id": "root", "component": "Text", "text": "Go"]], theme: theme)

        #expect(button < text)
    }

    @Test("An icon-only button keeps its width in a stretching column")
    func iconButtonKeepsItsWidth() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else { return }
        let measured = try #require(accentWidth([
            ["id": "root", "component": "Column", "children": ["button"]],
            ["id": "button", "component": "Button", "child": "icon", "variant": "primary", "action": ["event": ["name": "go"] as JsonMap] as JsonMap],
            ["id": "icon", "component": "Icon", "name": "favorite"]
        ]))

        #expect(measured < width / 2)
    }

    @Test("Children that share a row's width get equal shares")
    func rowChildrenShareItsWidthEqually() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else { return }
        var theme = A2UITheme()
        theme.surface = Color(red: 1, green: 0, blue: 0)
        let mask = try #require(redMask([
            ["id": "root", "component": "Row", "children": ["first", "second"]],
            ["id": "first", "component": "Card", "child": "firstText"],
            ["id": "firstText", "component": "Text", "text": "One"],
            ["id": "second", "component": "Card", "child": "secondText"],
            ["id": "secondText", "component": "Text", "text": "Two"]
        ], theme: theme))
        // A line through the cards' padding, above their text.
        let row = mask[6]
        var runs: [Int] = []
        for (x, isRed) in row.enumerated() where isRed {
            if x > 0, row[x - 1] { runs[runs.count - 1] += 1 } else { runs.append(1) }
        }

        #expect(runs.count == 2)
        #expect(abs((runs.first ?? 0) - (runs.last ?? 0)) <= 1)
    }

    private func button(variant: String, isRoot: Bool = false) -> [JsonMap] {
        [
            ["id": isRoot ? "root" : "button", "component": "Button", "child": "title", "variant": variant, "action": ["event": ["name": "go"] as JsonMap] as JsonMap],
            ["id": "title", "component": "Text", "text": "Go"]
        ]
    }

    private func surface(_ components: [JsonMap], theme: A2UITheme) -> some View {
        let processor = A2UIMessageProcessor(catalogs: [BasicCatalog.catalog], services: TestServices.make())
        processor.handle(
            .createSurface(
                CreateSurfaceMessage(
                    surfaceId: "main",
                    catalogId: BasicCatalog.catalogId,
                    components: components.compactMap { Component.fromJson($0) },
                    dataModel: [:]
                )
            )
        )
        return A2UISurface(host: processor, surfaceId: "main").environment(\.a2uiTheme, theme)
    }

    @available(iOS 16.0, macOS 13.0, *)
    private func height(_ components: [JsonMap], theme: A2UITheme = A2UITheme()) -> CGFloat {
        let renderer = ImageRenderer(content: surface(components, theme: theme).frame(width: width))
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        return renderer.cgImage.map { CGFloat($0.height) } ?? 0
    }

    // The width of what is drawn in the accent, at a scale of one point per pixel.
    @available(iOS 16.0, macOS 13.0, *)
    private func accentWidth(_ components: [JsonMap]) -> CGFloat? {
        var theme = A2UITheme()
        theme.accent = Color(red: 1, green: 0, blue: 0)
        guard let mask = redMask(components, theme: theme) else { return nil }
        let columns = mask.flatMap { row in row.indices.filter { row[$0] } }
        guard let first = columns.min(), let last = columns.max() else { return nil }
        return CGFloat(last - first + 1)
    }

    // Which pixels are red, row by row, at a scale of one point per pixel. Every case draws some
    // red, and the first render of a test run now and then has none, so a render without any is
    // drawn again.
    @available(iOS 16.0, macOS 13.0, *)
    private func redMask(_ components: [JsonMap], theme: A2UITheme) -> [[Bool]]? {
        for _ in 0..<3 {
            if let mask = renderRedMask(components, theme: theme), mask.contains(where: { $0.contains(true) }) {
                return mask
            }
        }
        return nil
    }

    @available(iOS 16.0, macOS 13.0, *)
    private func renderRedMask(_ components: [JsonMap], theme: A2UITheme) -> [[Bool]]? {
        let renderer = ImageRenderer(content: surface(components, theme: theme).frame(width: width).background(Color.white))
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        guard let image = renderer.cgImage else { return nil }
        let bytesPerRow = image.width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * image.height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        guard drawn else { return nil }
        return (0..<image.height).map { y in
            (0..<image.width).map { x in
                let offset = y * bytesPerRow + x * 4
                return pixels[offset] > 200 && pixels[offset + 1] < 60 && pixels[offset + 2] < 60
            }
        }
    }
}
