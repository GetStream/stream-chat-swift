//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension NSMutableAttributedString {
    /// Detects links in the string and applies `.link` attributes to them.
    ///
    /// Ranges that already have a `.link` attribute are left unchanged so
    /// Markdown-derived destinations are preserved when their display text
    /// itself looks like a URL (e.g. `[https://text-link.com](https://real-link.com)`).
    ///
    /// - Parameter detector: The detector used to find the links in the string.
    func addLinks(detectedBy detector: TextLinkDetector) {
        for textLink in detector.links(in: string) {
            var alreadyLinked = false
            enumerateAttribute(.link, in: textLink.range) { value, _, stop in
                if value != nil {
                    alreadyLinked = true
                    stop.pointee = true
                }
            }
            guard !alreadyLinked else { continue }
            addAttribute(.link, value: textLink.url, range: textLink.range)
        }
    }
}

@available(iOS 15, *)
@available(macOS 12, *)
public extension AttributedString {
    /// Detects links in the string and applies `.link` attributes to them.
    ///
    /// Ranges that already have a `.link` attribute are left unchanged so
    /// Markdown-derived destinations are preserved when their display text
    /// itself looks like a URL (e.g. `[https://text-link.com](https://real-link.com)`).
    ///
    /// - Parameter detector: The detector used to find the links in the string.
    mutating func addLinks(detectedBy detector: TextLinkDetector) {
        for textLink in detector.links(in: String(characters)) {
            guard let range = Range(textLink.range, in: self) else { continue }
            let alreadyLinked = self[range].runs.contains { $0.link != nil }
            guard !alreadyLinked else { continue }
            self[range].link = textLink.url
        }
    }
}
