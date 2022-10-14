//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol MarkdownFormatter {
    /// Checks for Markdown patterns in the given String.
    /// - Parameter text: The string in which Markdown patters are going to be sought.
    /// - Returns: Returns a Boolean value that indicates whether Markdown patters where found in the given String.
    func containsMarkdown(_ string: String) -> Bool
    /// Returns an attributed string form the given Markdown-formatted string.
    /// - Parameter string: The string to be formatted.
    /// - Returns: An attributed string with the corresponding formatted attributes.
    func format(_ string: String) -> NSAttributedString
}

/// Default implementation for the Markdown formatter
open class DefaultMarkdownFormatter: MarkdownFormatter {
    enum Attributes {
        enum Code {
            static let fontName: String = "CourierNewPSMT"
        }
    }
    
    private let markdownRegexPattern: String =
        "((?:\\`(.*?)\\`)|(?:\\*{1,2}(.*?)\\*{1,2})|(?:\\~{2}(.*?)\\~{2})|(?:\\_{1,2}(.*?)\\_{1,2})|^(>){1}|(#){1,6}|(=){3,10}|(-){1,3}|(\\d{1,3}\\.)|(?:\\[(.*?)\\])(?:\\((.*?)\\))|(?:\\[(.*?)\\])(?:\\[(.*?)\\])|(\\]\\:))+"
    
    open func containsMarkdown(_ string: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: markdownRegexPattern, options: .anchorsMatchLines) else {
            return false
        }
        
        return regex.numberOfMatches(in: string, range: .init(location: 0, length: string.utf16.count)) > 0
    }
    
    open func format(_ string: String) -> NSAttributedString {
        let markdownFormatter = SwiftyMarkdown(string: string)
        markdownFormatter.code.fontName = Attributes.Code.fontName
        return markdownFormatter.attributedString()
    }
}
