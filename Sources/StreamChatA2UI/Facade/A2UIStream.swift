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
        let bytes = Array(text.utf8)
        var messages: [String] = []
        var depth = 0
        var start = 0
        var inString = false
        var escaped = false
        for (index, byte) in bytes.enumerated() {
            if inString {
                if escaped {
                    escaped = false
                } else if byte == UInt8(ascii: "\\") {
                    escaped = true
                } else if byte == UInt8(ascii: "\"") {
                    inString = false
                }
                continue
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
                    messages.append(String(decoding: bytes[start...index], as: UTF8.self))
                }
            default:
                break
            }
        }
        return messages
    }
}
