//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 15, *)
struct HighlightedText: View {
    let text: String
    let searchText: String

    var body: some View {
        if searchText.isEmpty {
            Text(text)
        } else {
            let attributedString = highlightedAttributedString()
            Text(AttributedString(attributedString))
        }
    }

    private func highlightedAttributedString() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)

        // Find all occurrences of search text (case insensitive)
        let searchRange = text.range(of: searchText, options: .caseInsensitive)
        if let searchRange = searchRange {
            let nsRange = NSRange(searchRange, in: text)
            // Use appropriate color for the platform
            #if canImport(UIKit)
            let highlightColor = UIColor.systemYellow.withAlphaComponent(0.3)
            #elseif canImport(AppKit)
            let highlightColor = NSColor.systemYellow.withAlphaComponent(0.3)
            #endif
            attributedString.addAttribute(.backgroundColor, value: highlightColor, range: nsRange)
        }

        return attributedString
    }
}
