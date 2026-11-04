//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

@Suite("Citations")
struct CitationTests {
    let sources = [1: "https://example.com/a", 2: "https://example.com/b"]

    @Test func linksCitationsWithASource() {
        #expect(Citations.link("Lakes [1] and towns [2].", sources: sources)
            == "Lakes [[1]](https://example.com/a) and towns [[2]](https://example.com/b).")
        #expect(Citations.link("Missing [3], wide [123], none [].", sources: sources) == "Missing [3], wide [123], none [].")
    }

    @Test func leavesCodeAsWritten() {
        let text = """
        Use `items[1]` or ``a[1]`` here [1].
        ```swift
        let first = items[1]
        ```
          ~~~
          list[2]
          ~~~
        Done [2]
        """

        #expect(Citations.link(text, sources: sources) == """
        Use `items[1]` or ``a[1]`` here [[1]](https://example.com/a).
        ```swift
        let first = items[1]
        ```
          ~~~
          list[2]
          ~~~
        Done [[2]](https://example.com/b)
        """)
    }

    @Test func leavesLinksAndEscapesAlone() {
        #expect(Citations.link("[[1]](https://x.dev) [1](https://y.dev) \\[1] [1]: https://z.dev", sources: sources)
            == "[[1]](https://x.dev) [1](https://y.dev) \\[1] [1]: https://z.dev")
        #expect(Citations.link("An `open [1] span", sources: sources) == "An `open [[1]](https://example.com/a) span")
    }

    @Test func encodesURLsOnce() {
        #expect(Citations.destination("https://example.com/a%20b") == "https://example.com/a%20b")
        #expect(Citations.destination("https://example.com/a b") == "https://example.com/a%20b")
        #expect(Citations.destination("https://en.wikipedia.org/wiki/Ohrid_(city)") == "https://en.wikipedia.org/wiki/Ohrid_%28city%29")
        #expect(Citations.destination("not a url") == nil)
    }

    @Test func linkedCitationsOpenTheirSource() {
        let text = Citations.link("See [1].", sources: [1: "https://example.com/a b"])
        let links = InlineMarkdown.attributed(text).runs.compactMap(\.link)

        #expect(links.map(\.absoluteString) == ["https://example.com/a%20b"])
    }
}
