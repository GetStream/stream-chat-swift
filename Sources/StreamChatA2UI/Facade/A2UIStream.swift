//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The A2UI messages of a reply as the agent writes them.
///
/// A message is a JSON object, and an agent writes them one per line, pretty-printed or in an
/// array. Each complete one counts, in order, and the one still being written does not, so a UI
/// shows as its messages arrive.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIStream {
    /// The complete messages in `text`, as written.
    static func messages(in text: String) -> [String] {
        var scanner = A2UIStreamScanner()
        scanner.scan(text)
        return scanner.messages
    }
}

// Finds the complete messages of a reply as it grows, parsing only the text added since the
// last scan, so a reply streamed in many chunks is parsed once rather than once per chunk. Telling
// whether the text carries on from the last still compares all of the earlier text, as the reply
// can be rewritten anywhere, but with `memcmp`, far faster than parsing it.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIStreamScanner {
    private(set) var messages: [String] = []
    private var source = ""
    private var scanned = 0
    private var depth = 0
    private var start = 0
    private var inString = false
    private var escaped = false

    // Whether the text after the last complete message starts one that isn't complete.
    var hasOpenMessage: Bool {
        depth > 0
    }

    // Scans `text` for messages. Returns false when it doesn't carry on from the text scanned
    // before, so it was scanned again from its start, and messages found before may have changed.
    @discardableResult
    mutating func scan(_ text: String) -> Bool {
        var text = text
        let carriesOn = Self.text(&text, startsWith: &source)
        if !carriesOn {
            self = A2UIStreamScanner()
        }
        source = text
        text.withUTF8 { bytes in
            for index in scanned..<bytes.count {
                read(bytes[index], at: index, in: bytes)
            }
            scanned = bytes.count
        }
        return carriesOn
    }

    private mutating func read(_ byte: UInt8, at index: Int, in bytes: UnsafeBufferPointer<UInt8>) {
        if inString {
            if escaped {
                escaped = false
            } else if byte == UInt8(ascii: "\\") {
                escaped = true
            } else if byte == UInt8(ascii: "\"") {
                inString = false
            }
            return
        }
        switch byte {
        case UInt8(ascii: "\"") where depth > 0:
            inString = true
        case UInt8(ascii: "{"):
            if depth == 0 { start = index }
            depth += 1
        case UInt8(ascii: "}") where depth > 0:
            depth -= 1
            if depth == 0 {
                messages.append(String(decoding: UnsafeBufferPointer(rebasing: bytes[start...index]), as: UTF8.self))
            }
        default:
            break
        }
    }

    private static func text(_ text: inout String, startsWith prefix: inout String) -> Bool {
        text.withUTF8 { bytes in
            prefix.withUTF8 { prefixBytes in
                guard prefixBytes.count <= bytes.count else { return false }
                guard let base = bytes.baseAddress, let prefixBase = prefixBytes.baseAddress else { return true }
                return memcmp(base, prefixBase, prefixBytes.count) == 0
            }
        }
    }
}
