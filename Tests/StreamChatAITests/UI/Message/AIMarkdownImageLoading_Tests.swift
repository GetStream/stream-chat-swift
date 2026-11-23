//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import SwiftUI
import XCTest

final class AIMarkdownImageLoading_Tests: XCTestCase {
    func test_byDefault_noImageLoads() {
        XCTAssertFalse(EnvironmentValues().aiMarkdownImageLoading.loads(URL(string: "https://images.example.com/a.png")!))
    }

    func test_never_showsAnImageAsALinkToItsAddress() {
        let content = MarkdownContent("Here: ![a chart](https://cdn.example/p.png?w=200)").loadingImages(.never)

        XCTAssertEqual(content.blocks, [
            .paragraph(content: [
                .text("Here: "),
                .link(destination: "https://cdn.example/p.png?w=200", children: [.text("Image: a chart")])
            ])
        ])
    }

    func test_never_namesTheHostOfAnImageWithoutADescription() {
        let content = MarkdownContent("![](https://cdn.example/p.png)").loadingImages(.never)

        XCTAssertEqual(content.blocks, [
            .paragraph(content: [.link(destination: "https://cdn.example/p.png", children: [.text("Image: cdn.example")])])
        ])
    }

    func test_hosts_loadsOnlyHTTPSImagesFromThoseHosts() {
        let markdown = """
        ![a](https://images.example.com/a.png) ![b](http://images.example.com/b.png) ![c](https://other.example/c.png)
        """

        let content = MarkdownContent(markdown).loadingImages(.hosts(["Images.Example.com"]))

        XCTAssertEqual(content.blocks, [
            .paragraph(content: [
                .image(source: "https://images.example.com/a.png", children: [.text("a")]),
                .text(" "),
                .link(destination: "http://images.example.com/b.png", children: [.text("Image: b")]),
                .text(" "),
                .link(destination: "https://other.example/c.png", children: [.text("Image: c")])
            ])
        ])
    }

    func test_custom_loadsTheImagesItAccepts() {
        let loading = AIMarkdownImageLoading.custom { $0.path.hasPrefix("/allowed/") }

        XCTAssertTrue(loading.loads(URL(string: "https://cdn.example/allowed/a.png")!))
        XCTAssertFalse(loading.loads(URL(string: "https://cdn.example/other/a.png")!))
        XCTAssertFalse(loading.loads(URL(string: "http://cdn.example/allowed/a.png")!))
    }

    func test_anImageInALink_becomesTheLinksText() {
        let content = MarkdownContent("[![a](https://cdn.example/a.png)](https://site.example)").loadingImages(.never)

        XCTAssertEqual(content.blocks, [
            .paragraph(content: [.link(destination: "https://site.example", children: [.text("Image: a")])])
        ])
    }

    func test_aFormattedImageInALink_becomesFormattedText() {
        let markdown = "[**![a](https://cdn.example/a.png)** and *~~![b](https://cdn.example/b.png)~~*](https://site.example)"

        let content = MarkdownContent(markdown).loadingImages(.never)

        XCTAssertEqual(content.blocks, [
            .paragraph(content: [
                .link(destination: "https://site.example", children: [
                    .strong(children: [.text("Image: a")]),
                    .text(" and "),
                    .emphasis(children: [.strikethrough(children: [.text("Image: b")])])
                ])
            ])
        ])
    }

    func test_anImageWithoutAWebAddress_showsAsText() {
        let content = MarkdownContent("![a](file:///etc/hosts) ![b](b.png)").loadingImages(.custom { _ in true })

        XCTAssertEqual(content.blocks, [
            .paragraph(content: [.text("Image: a"), .text(" "), .text("Image: b")])
        ])
    }

    func test_imagesInQuotesListsAndTables_becomeLinks() {
        let markdown = """
        > ![q](https://cdn.example/q.png)

        - ![l](https://cdn.example/l.png)

        | ![t](https://cdn.example/t.png) |
        | --- |
        """

        let content = MarkdownContent(markdown).loadingImages(.never)

        XCTAssertFalse(content.blocks.containsImage)
    }
}

private extension Array where Element == BlockNode {
    var containsImage: Bool {
        var found = false
        _ = rewrite { (inline: InlineNode) -> [InlineNode] in
            if case .image = inline { found = true }
            return [inline]
        }
        return found
    }
}
