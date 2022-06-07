//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit

extension SwiftyMarkdown {
    func font(for line: SwiftyLine, characterOverride: CharacterStyle? = nil) -> NSFont {
        var fontName: String?
        var fontSize: CGFloat?
		
        var globalBold = false
        var globalItalic = false
		
        let style: FontProperties
        // What type are we and is there a font name set?
        switch line.lineStyle as! MarkdownLineStyle {
        case .h1:
            style = h1
        case .h2:
            style = h2
        case .h3:
            style = h3
        case .h4:
            style = h4
        case .h5:
            style = h5
        case .h6:
            style = h6
        case .codeblock:
            style = code
        case .blockquote:
            style = blockquotes
        default:
            style = body
        }
		
        fontName = style.fontName
        fontSize = style.fontSize
        switch style.fontStyle {
        case .bold:
            globalBold = true
        case .italic:
            globalItalic = true
        case .boldItalic:
            globalItalic = true
            globalBold = true
        case .normal:
            break
        }

        if fontName == nil {
            fontName = body.fontName
        }
		
        if let characterOverride = characterOverride {
            switch characterOverride {
            case .code:
                fontName = code.fontName ?? fontName
                fontSize = code.fontSize
            case .link:
                fontName = link.fontName ?? fontName
                fontSize = link.fontSize
            case .bold:
                fontName = bold.fontName ?? fontName
                fontSize = bold.fontSize
                globalBold = true
            case .italic:
                fontName = italic.fontName ?? fontName
                fontSize = italic.fontSize
                globalItalic = true
            default:
                break
            }
        }
		
        fontSize = fontSize == 0.0 ? nil : fontSize
        let finalSize: CGFloat
        if let existentFontSize = fontSize {
            finalSize = existentFontSize
        } else {
            finalSize = NSFont.systemFontSize
        }
        var font: NSFont
        if let existentFontName = fontName {
            if let customFont = NSFont(name: existentFontName, size: finalSize) {
                font = customFont
            } else {
                font = NSFont.systemFont(ofSize: finalSize)
            }
        } else {
            font = NSFont.systemFont(ofSize: finalSize)
        }
		
        if globalItalic {
            let italicDescriptor = font.fontDescriptor.withSymbolicTraits(.italic)
            font = NSFont(descriptor: italicDescriptor, size: 0) ?? font
        }
        if globalBold {
            let boldDescriptor = font.fontDescriptor.withSymbolicTraits(.bold)
            font = NSFont(descriptor: boldDescriptor, size: 0) ?? font
        }
		
        return font
    }
	
    func color(for line: SwiftyLine) -> NSColor {
        // What type are we and is there a font name set?
        switch line.lineStyle as! MarkdownLineStyle {
        case .h1, .previousH1:
            return h1.color
        case .h2, .previousH2:
            return h2.color
        case .h3:
            return h3.color
        case .h4:
            return h4.color
        case .h5:
            return h5.color
        case .h6:
            return h6.color
        case .body:
            return body.color
        case .codeblock:
            return code.color
        case .blockquote:
            return blockquotes.color
        case .unorderedList, .unorderedListIndentFirstOrder, .unorderedListIndentSecondOrder, .orderedList,
             .orderedListIndentFirstOrder, .orderedListIndentSecondOrder:
            return body.color
        case .yaml:
            return body.color
        case .referencedLink:
            return body.color
        }
    }
}
#endif
