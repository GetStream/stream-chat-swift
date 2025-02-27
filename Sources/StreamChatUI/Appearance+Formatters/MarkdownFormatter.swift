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
    public var markdownRegexPattern: String {
        didSet {
            if let regex = try? NSRegularExpression(pattern: markdownRegexPattern, options: .anchorsMatchLines) {
                self.regex = regex
            } else {
                log.error("Failed to create markdown regular expression")
            }
        }
    }
    
    public init() {
        styles = MarkdownStyles()
        markdownRegexPattern = ""
    }
    
    private let markdownParser = MarkdownParser()
    private var regex: NSRegularExpression?
    
    open func containsMarkdown(_ string: String) -> Bool {
        // Note: this method is not needed because MarkdownParser returns regular text if there is no markdown.
        // When we can make a breaking change, this method should be deprecated.
        if markdownRegexPattern.isEmpty {
            // Text is always parsed
            return true
        }
        guard let regex = regex else { return false }
        return regex.numberOfMatches(in: string, range: .init(location: 0, length: string.utf16.count)) > 0
    }

    open func format(_ string: String) -> NSAttributedString {
        if #available(iOS 15, *), !string.isEmpty {
            do {
                let attributedString = try markdownParser.style(
                    markdown: string,
                    options: .init(layoutDirectionLeftToRight: UITraitCollection.current.layoutDirection == .leftToRight),
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
    private var fonts: Appearance.Fonts { Appearance.default.fonts }
    
    private var defaultAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.font(forMarkdownFont: styles.bodyFont, defaultFont: fonts.body),
            .foregroundColor: styles.bodyFont.color ?? Appearance.default.colorPalette.text
        ]
    }
    
    @available(iOS 15, *)
    private func inlinePresentationIntentAttributes(for inlinePresentationIntent: InlinePresentationIntent) -> AttributeContainer? {
        switch inlinePresentationIntent {
        case .code:
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.font(forMarkdownFont: styles.codeFont, defaultFont: fonts.body, monospaced: true),
                .foregroundColor: styles.codeFont.color
            ].compactMapValues { $0 }
            return AttributeContainer(attributes)
        case .extremelyStronglyEmphasized:
            let font = UIFont.font(forMarkdownFont: styles.bodyFont, defaultFont: fonts.body)
                .withTraits(traits: [.traitBold, .traitItalic])
            return AttributeContainer([.font: font])
        default:
            // emphasized etc are handled automatically by UITextView
            return nil
        }
    }
    
    @available(iOS 15, *)
    private func presentationIntentAttributes(for presentationKind: PresentationIntent.Kind, in presentationIntent: PresentationIntent) -> AttributeContainer? {
        switch presentationKind {
        case .blockQuote:
            return AttributeContainer([
                .foregroundColor: colorPalette.subtitleText
            ])
        case .codeBlock:
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.font(forMarkdownFont: styles.codeFont, defaultFont: fonts.body, monospaced: true),
                .foregroundColor: styles.codeFont.color
            ].compactMapValues { $0 }
            return AttributeContainer(attributes)
        case .header(let level):
            let font: UIFont
            let foregroundColor: UIColor?
            switch level {
            case 1:
                font = UIFont.font(forMarkdownFont: styles.h1Font, defaultFont: fonts.title, textStyle: .title1)
                foregroundColor = styles.h1Font.color
            case 2:
                font = UIFont.font(forMarkdownFont: styles.h2Font, defaultFont: fonts.title2, textStyle: .title2)
                foregroundColor = styles.h2Font.color
            case 3:
                font = UIFont.font(forMarkdownFont: styles.h3Font, defaultFont: fonts.title3, textStyle: .title3)
                foregroundColor = styles.h3Font.color
            case 4:
                font = UIFont.font(forMarkdownFont: styles.h4Font, defaultFont: fonts.headline, textStyle: .headline)
                foregroundColor = styles.h4Font.color
            case 5:
                font = UIFont.font(forMarkdownFont: styles.h5Font, defaultFont: fonts.subheadline, textStyle: .subheadline)
                foregroundColor = styles.h5Font.color
            default:
                font = UIFont.font(forMarkdownFont: styles.h6Font, defaultFont: fonts.footnote, textStyle: .footnote)
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
            return nil
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
        defaultFont: UIFont,
        textStyle: TextStyle = .body,
        monospaced: Bool = false
    ) -> UIFont {
        if !markdownFont.hasFontChanges && !monospaced {
            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: defaultFont)
        }
        // Default
        var descriptor = defaultFont.fontDescriptor
        if monospaced, let updatedDescriptor = descriptor.withDesign(.monospaced) {
            descriptor = updatedDescriptor
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

@available(iOS 15.0, *)
private extension InlinePresentationIntent {
    /// An intent that represents bold with italic presentation.
    static var extremelyStronglyEmphasized = InlinePresentationIntent(rawValue: 3)
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
