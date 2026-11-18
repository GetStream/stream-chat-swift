//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing
@Suite("Incremental stream scanning")
struct StreamScannerTests {
    @Test("Scanning a reply chunk by chunk finds what one scan of it does")
    func chunks() {
        let text = #"{"version":"1.0","createSurface":{"surfaceId":"a"}} {"text":"a } \" { b"} {"open":"#
        var scanner = A2UIStreamScanner()
        var source = ""
        for character in text {
            source.append(character)
            let carriesOn = scanner.scan(source)
            #expect(carriesOn)
        }

        #expect(scanner.messages == A2UIStream.messages(in: text))
        #expect(scanner.messages.count == 2)
        #expect(scanner.hasOpenMessage)
    }

    @Test("Text that doesn't carry on from the last is scanned again")
    func rewrite() {
        var scanner = A2UIStreamScanner()
        scanner.scan(#"{"a":1} {"b":2}"#)

        let carriesOn = scanner.scan(#"{"c":3}"#)
        #expect(!carriesOn)
        #expect(scanner.messages == [#"{"c":3}"#])
        #expect(!scanner.hasOpenMessage)
    }
}
