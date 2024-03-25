//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
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
    public var styles: MarkdownStyles
    public var markdownRegexPattern: String

    private let defaultMarkdownRegex = "((?:\\`(.*?)\\`)|(?:\\*{1,2}(.*?)\\*{1,2})|(?:\\~{2}(.*?)\\~{2})|(?:\\_{1,2}(.*?)\\_{1,2})|^(>){1}|(#){1,6}|(=){3,10}|(-){1,3}|(\\d{1,3}\\.)|(?:\\[(.*?)\\])(?:\\((.*?)\\))|(?:\\[(.*?)\\])(?:\\[(.*?)\\])|(\\]\\:))+"

    public init() {
        styles = MarkdownStyles()
        markdownRegexPattern = defaultMarkdownRegex
    }

    private lazy var regex: NSRegularExpression? = {
        guard let regex = try? NSRegularExpression(pattern: markdownRegexPattern, options: .anchorsMatchLines) else {
            log.error("Failed to create markdown regular expression")
            return nil
        }
        return regex
    }()
    
    open func containsMarkdown(_ string: String) -> Bool {
        guard let regex = regex else { return false }
        return regex.numberOfMatches(in: string, range: .init(location: 0, length: string.utf16.count)) > 0
    }

    open func format(_ string: String) -> NSAttributedString {
        let markdownFormatter = SwiftyMarkdown(string: string)
        modify(swiftyMarkdownFont: markdownFormatter.code, with: styles.codeFont)
        modify(swiftyMarkdownFont: markdownFormatter.body, with: styles.bodyFont)
        modify(swiftyMarkdownFont: markdownFormatter.link, with: styles.linkFont)
        modify(swiftyMarkdownFont: markdownFormatter.h1, with: styles.h1Font)
        modify(swiftyMarkdownFont: markdownFormatter.h2, with: styles.h2Font)
        modify(swiftyMarkdownFont: markdownFormatter.h3, with: styles.h3Font)
        modify(swiftyMarkdownFont: markdownFormatter.h4, with: styles.h4Font)
        modify(swiftyMarkdownFont: markdownFormatter.h5, with: styles.h5Font)
        modify(swiftyMarkdownFont: markdownFormatter.h6, with: styles.h6Font)
        return markdownFormatter.attributedString()
    }

    private func modify(swiftyMarkdownFont: FontProperties, with font: MarkdownFont) {
        if let fontName = font.name {
            swiftyMarkdownFont.fontName = fontName
        }
        if let fontSize = font.size {
            swiftyMarkdownFont.fontSize = fontSize
        }
        if let fontColor = font.color {
            swiftyMarkdownFont.color = fontColor
        }
        if let fontStyle = font.styling?.asSwiftyMarkdownFontStyle() {
            swiftyMarkdownFont.fontStyle = fontStyle
        }
    }
}

/// Configures the font style properties for base Markdown elements
public struct MarkdownStyles {
    /// The regular paragraph font.
    public var bodyFont: MarkdownFont = .init()

    /// The font used for coding blocks in markdown text.
    public var codeFont: MarkdownFont = .init()

    /// The font used for links found in markdown text.
    public var linkFont: MarkdownFont = .init()

    /// The font used for H1 headers in markdown text.
    public var h1Font: MarkdownFont = .init()

    /// The font used for H2 headers in markdown text.
    public var h2Font: MarkdownFont = .init()

    /// The font used for H3 headers in markdown text.
    public var h3Font: MarkdownFont = .init()

    /// The font used for H4 headers in markdown text.
    public var h4Font: MarkdownFont = .init()

    /// The font used for H5 headers in markdown text.
    public var h5Font: MarkdownFont = .init()

    /// The font used for H6 headers in markdown text.
    public var h6Font: MarkdownFont = .init()

    public init() {
        codeFont.name = "CourierNewPSMT"
    }
}

public struct MarkdownFont {
    public var name: String?
    public var size: Double?
    public var color: UIColor?
    public var styling: MarkdownFontStyle?

    public init() {
        name = nil
        size = nil
        color = nil
        styling = nil
    }
}

public enum MarkdownFontStyle: Int {
    case normal
    case bold
    case italic
    case boldItalic

    func asSwiftyMarkdownFontStyle() -> FontStyle {
        switch self {
        case .normal:
            return .normal
        case .bold:
            return .bold
        case .italic:
            return .italic
        case .boldItalic:
            return .boldItalic
        }
    }
}
