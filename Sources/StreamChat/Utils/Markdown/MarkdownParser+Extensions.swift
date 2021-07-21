//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public extension MarkdownParser {
    static let shared = MarkdownParser()
    
    static func makeMarkdownText(from text: String) -> NSMutableAttributedString? {
        guard text.mightHaveMarkdown else { return nil }
        return shared.parse(text).htmlAttributedString
    }
}

private extension String {
    var mightHaveMarkdown: Bool {
        for character in self {
            if ["\\", "`", "*", "_", "[", "]", "(", ")", "#", "+", "-", ".", "!"].contains(character) {
                return true
            }
        }
        return false
    }
    
    var htmlAttributedString: NSMutableAttributedString? {
        guard let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return nil }
        
        guard let formattedString = try? NSMutableAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) else { return nil }
        
        // Rendering plain text into MD wraps it inside <p> block which add an extra unecessary new line
        // at the end of text
        if formattedString.length > 2 {
            formattedString.mutableString.replaceOccurrences(
                of: "\n",
                with: "",
                options: [],
                range: NSRange(location: formattedString.length - 2, length: 2)
            )
        }
        
        return formattedString
    }
}
