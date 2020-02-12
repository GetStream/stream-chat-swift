//
//  EnrichableMessageText.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 18/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatCore
import RxSwift
import UIKit

final class MessageTextEnrichment {
    
    let message: Message
    let style: MessageViewStyle
    private(set) var text: String
    let addMarkdown: Bool
    let enrichURLs: Bool
    let mentionedUserNames: [String]
    private(set) var detectedURLs = [DataDetectorURLItem]()
    private(set) var attributedString: NSMutableAttributedString?
    
    private lazy var quoteAttributesForMarkers: [Int: [NSAttributedString.Key: Any]] =
        [2: [.font: style.font.withTraits(.traitBold), .foregroundColor: style.replyColor],
         3: [.font: style.font.withTraits(.traitBold), .foregroundColor: style.replyColor.withAlphaComponent(0.8)],
         4: [.font: style.font.withTraits(.traitBold), .foregroundColor: style.replyColor.withAlphaComponent(0.6)]]
    
    private lazy var quoteAttributesForText: [NSAttributedString.Key: Any] =
        [.font: style.font.withTraits(.traitItalic), .foregroundColor: style.textColor.withAlphaComponent(0.7)]
    
    private lazy var strikethroughAttributes: [NSAttributedString.Key: Any] =
        [.strikethroughStyle: NSUnderlineStyle.single.rawValue, .strikethroughColor: style.textColor]
    
    init?(_ message: Message, style: MessageViewStyle?, enrichURLs: Bool = true) {
        guard let style = style, message.text.count > 2, !message.text.messageContainsOnlyEmoji else {
            return nil
        }
        
        let addMarkdown = style.markdownEnabled
            && message.text.replacingOccurrences(of: "~~", with: "-").rangeOfCharacter(from: .markdown) != nil
        let mentionedUserNames = message.mentionedUsers.map({ $0.name })
        
        let enrichURLs = enrichURLs && message.text.probablyHasURL
        
        if !addMarkdown, !enrichURLs, mentionedUserNames.isEmpty {
            return nil
        }
        
        self.message = message
        self.style = style
        self.text = message.text
        self.addMarkdown = addMarkdown
        self.enrichURLs = enrichURLs
        self.mentionedUserNames = mentionedUserNames
        attributedString = NSMutableAttributedString(string: text)
    }
    
    var defaultAttributedString: NSMutableAttributedString {
        return NSMutableAttributedString(string: text,
                                         attributes: [.font: style.font,
                                                      .foregroundColor: style.textColor,
                                                      .backgroundColor: style.backgroundColor])
    }
    
    func enrich() -> Observable<NSAttributedString> {
        return Observable.create({ [weak self] observer -> Disposable in
            if let self = self {
                self.parseLinks()
                self.parse()
                
                if let attributedString = self.attributedString {
                    observer.onNext(attributedString)
                }
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        })
    }
}

// MARK: - Parser

private extension MessageTextEnrichment {
    
    func parse() {
        var affected = false
        let attributedString = self.attributedString ?? defaultAttributedString
        let boldFont = style.font.withTraits(.traitBold)
        
        // Add mentioned users.
        if !mentionedUserNames.isEmpty {
            affected = addAttributes(to: attributedString, text: text.lowercased(), attributes: [.font: boldFont]) || affected
        }
        
        // Add markdown.
        if addMarkdown {
            // Add Bold.
            affected = addAttributes(to: attributedString,
                                     regexKeyChar: "\\*\\*|__",
                                     attributes: [.font: boldFont]) || affected
            
            // Add Italic.
            affected = addAttributes(to: attributedString,
                                     regexKeyChar: "\\*|_",
                                     attributes: [.font: style.font.withTraits(.traitItalic)]) || affected
            
            // Add Strikethrough.
            affected = addAttributes(to: attributedString, regexKeyChar: "-", attributes: strikethroughAttributes) || affected
            affected = addAttributes(to: attributedString, regexKeyChar: "~~", attributes: strikethroughAttributes) || affected
            
            // Add Code.
            if let font = UIFont.monospaced(size: (style.font.pointSize - 1)) {
                affected = addAttributes(to: attributedString, regexKeyChar: "`", attributes: [.font: font]) || affected
            }
            
            // Add quotes.
            affected = addQuoteAttributes(to: attributedString) || affected
        }
        
        if affected {
            self.attributedString = attributedString
        }
    }
    
    private func addAttributes(to attributedText: NSMutableAttributedString,
                               text: String,
                               attributes: [NSAttributedString.Key: Any]) -> Bool {
        var affected = false
        
        for name in mentionedUserNames {
            guard let range = text.range(of: name.lowercased()) else {
                continue
            }
            
            let nsRange = text.nsRange(from: range)
            attributedText.replaceCharacters(in: nsRange, with: name)
            attributedText.addAttributes(attributes, range: nsRange)
            affected = true
            
            // Add a shadow for `@`.
            if nsRange.location > 0 {
                let atRange = NSRange(location: nsRange.location - 1, length: 1)
                attributedText.addAttributes([.foregroundColor: style.textColor.withAlphaComponent(0.5)], range: atRange)
            }
        }
        
        return affected
    }
    
    private func addAttributes(to attributedText: NSMutableAttributedString,
                               regexKeyChar: String,
                               attributes: [NSAttributedString.Key: Any]) -> Bool {
        guard let regularExpression = try? NSRegularExpression(pattern: "(\\s+|^)(\(regexKeyChar))(.+?)(\\2)", options: []) else {
            return false
        }
        
        var location = 0
        
        while let match = regularExpression
            .firstMatch(in: attributedText.string,
                        options: .withoutAnchoringBounds,
                        range: NSRange(location: location, length: attributedText.length - location)) {
                            let oldLength = attributedText.length
                            attributedText.deleteCharacters(in: match.range(at: 4))
                            attributedText.addAttributes(attributes, range: match.range(at: 3))
                            attributedText.deleteCharacters(in: match.range(at: 2))
                            let newLength = attributedText.length
                            location = match.range.location + match.range.length + newLength - oldLength
        }
        
        return true
    }
    
    private func addQuoteAttributes(to attributedText: NSMutableAttributedString) -> Bool {
        guard attributedText.string.contains(">"),
            let regularExpression = try? NSRegularExpression(pattern: "(^|\n)(\\>)(\\>)?(\\>)?\\s*(.+)($|\n)", options: []) else {
                return false
        }
        
        let matches = regularExpression.matches(in: attributedText.string,
                                                options: .withoutAnchoringBounds,
                                                range: NSRange(location: 0, length: attributedText.length))
        
        matches.forEach { match in
            for index in 2...4 {
                let range = match.range(at: index)
                
                if range.location != NSNotFound {
                    attributedText.replaceCharacters(in: range, with: "|")
                    attributedText.addAttributes(quoteAttributesForMarkers[index, default: [:]], range: range)
                }
            }
            
            attributedText.addAttributes(quoteAttributesForText, range: match.range(at: 5))
        }
        
        return true
    }
    
    // MARK: Parse Links
    
    func parseLinks() {
        guard enrichURLs else {
            return
        }
        
        detectedURLs = DataDetector.shared.matchURLs(text)
        
        if detectedURLs.isEmpty {
            return
        }
        
        let attributedString = self.attributedString ?? defaultAttributedString
        
        for detectedURL in detectedURLs {
            attributedString.addAttributes([.foregroundColor: style.replyColor], range: detectedURL.range)
        }
        
        self.attributedString = attributedString
    }
}
