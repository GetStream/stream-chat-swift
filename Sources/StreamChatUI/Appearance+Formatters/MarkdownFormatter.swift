//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        if #available(iOS 15, *) {
            do {
                let attributedString = try MarkdownParser.style(
                    markdown: string,
                    attributes: AttributeContainer(defaultAttributes),
                    inlinePresentationIntentAttributes: inlinePresentationIntentAttributes(for:),
                    presentationIntentAttributes: presentationIntentAttributes(for:in:)
                )
                return NSAttributedString(attributedString)
            } catch {
                log.debug("Failed to parse string for markdown: \(error.localizedDescription)")
            }
        }
        return NSAttributedString(
            string: string,
            attributes: defaultAttributes
        )
    }

    // MARK: - Styling Attributes
    
    private var colorPalette: Appearance.ColorPalette { Appearance.default.colorPalette }
    
    private var defaultAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.font(forMarkdownFont: styles.bodyFont),
            .foregroundColor: styles.bodyFont.color ?? Appearance.default.colorPalette.text
        ]
    }
    
    @available(iOS 15, *)
    private func inlinePresentationIntentAttributes(for inlinePresentationIntent: InlinePresentationIntent) -> AttributeContainer? {
        switch inlinePresentationIntent {
        case .code:
            let attributes: [NSAttributedString.Key: Any] = [
                // Inline currently does not have background color, although many editors prefer to do this
                .font: UIFont.font(forMarkdownFont: styles.codeFont, monospaced: true),
                .foregroundColor: styles.codeFont.color
            ].compactMapValues { $0 }
            return AttributeContainer(attributes)
        default:
            // emphasized etc are handled automatically by UITextView
            return nil
        }
    }
    
    @available(iOS 15, *)
    private func presentationIntentAttributes(for presentationKind: PresentationIntent.Kind, in presentationIntent: PresentationIntent) -> AttributeContainer {
        switch presentationKind {
        case .blockQuote:
            return AttributeContainer([
                .foregroundColor: colorPalette.subtitleText
            ])
        case .codeBlock:
            let attributes: [NSAttributedString.Key: Any] = [
                .backgroundColor: colorPalette.background2,
                .font: UIFont.font(forMarkdownFont: styles.codeFont, monospaced: true),
                .foregroundColor: styles.codeFont.color
            ].compactMapValues { $0 }
            return AttributeContainer(attributes)
        case .header(let level):
            let font: UIFont
            let foregroundColor: UIColor?
            switch level {
            case 1:
                font = UIFont.font(forMarkdownFont: styles.h1Font, textStyle: .title1, weight: .bold)
                foregroundColor = styles.h1Font.color
            case 2:
                font = UIFont.font(forMarkdownFont: styles.h2Font, textStyle: .title2, weight: .bold)
                foregroundColor = styles.h2Font.color
            case 3:
                font = UIFont.font(forMarkdownFont: styles.h3Font, textStyle: .title3, weight: .bold)
                foregroundColor = styles.h3Font.color
            case 4:
                font = UIFont.font(forMarkdownFont: styles.h4Font, textStyle: .headline, weight: .semibold)
                foregroundColor = styles.h4Font.color
            case 5:
                font = UIFont.font(forMarkdownFont: styles.h5Font, textStyle: .subheadline, weight: .semibold)
                foregroundColor = styles.h5Font.color
            default:
                font = UIFont.font(forMarkdownFont: styles.h6Font, textStyle: .footnote, weight: .semibold)
                foregroundColor = styles.h6Font.color ?? colorPalette.subtitleText
            }
            if let foregroundColor {
                return AttributeContainer([.font: font, .foregroundColor: foregroundColor])
            } else {
                return AttributeContainer([.font: font])
            }
        case .listItem:
            return AttributeContainer([
                .paragraphStyle: listItemParagraphStyle(forIndentationLevel: presentationIntent.indentationLevel)
            ])
        default:
            return AttributeContainer()
        }
    }
    
    // MARK: - Paragraph Styles
    
    private func listItemParagraphStyle(forIndentationLevel level: Int) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        let location = style.tabStops.first?.location ?? 28
        style.headIndent = CGFloat(level) * location
        return style
    }
}

private extension UIFont {
    static func font(
        forMarkdownFont markdownFont: MarkdownFont,
        textStyle: TextStyle = .body,
        weight: Weight? = nil,
        monospaced: Bool = false
    ) -> UIFont {
        // Default
        var descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        if monospaced, let updatedDescriptor = descriptor.withDesign(.monospaced) {
            descriptor = updatedDescriptor
        }
        if let weight {
            descriptor = descriptor.withWeight(weight)
        }
        
        // MarkdownFont
        // When changing family, the descriptor should be reset
        if let fontName = markdownFont.name {
            descriptor = UIFontDescriptor(name: fontName, size: descriptor.pointSize)
        }
        if let size = markdownFont.size {
            descriptor = descriptor.withSize(size)
        }
        if let traits = markdownFont.styling?.symbolicTraits(), let descriptorWithTraits = descriptor.withSymbolicTraits(traits) {
            descriptor = descriptorWithTraits
        }
        let font = UIFont(descriptor: descriptor, size: descriptor.pointSize)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
    }
}

private extension UIFontDescriptor {
    func withWeight(_ weight: UIFont.Weight) -> UIFontDescriptor {
        addingAttributes(([.traits: [UIFontDescriptor.TraitKey.weight: weight]]))
    }
}

/// Configures the font style properties for base Markdown elements
public struct MarkdownStyles {
    /// The regular paragraph font.
    public var bodyFont: MarkdownFont = .init()

    /// The font used for coding blocks in markdown text.
    public var codeFont: MarkdownFont = .init()

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
    
    var hasFontChanges: Bool {
        name != nil || size != nil || styling != nil
    }
}

public enum MarkdownFontStyle: Int {
    case normal
    case bold
    case italic
    case boldItalic

    func symbolicTraits() -> UIFontDescriptor.SymbolicTraits? {
        switch self {
        case .normal:
            return nil
        case .bold:
            return .traitBold
        case .italic:
            return .traitItalic
        case .boldItalic:
            return [UIFontDescriptor.SymbolicTraits.traitBold, UIFontDescriptor.SymbolicTraits.traitItalic]
        }
    }
}
