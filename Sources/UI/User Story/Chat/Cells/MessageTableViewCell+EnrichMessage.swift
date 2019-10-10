//
//  MessageTableViewCell+EnrichMessage.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 18/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift

extension MessageTableViewCell {
    
    func enrichMessage(with text: String, mentionedUsersNames: [String], style: MessageViewStyle) -> Observable<NSAttributedString> {
        return Observable.create({ [weak self] observer -> Disposable in
            if let self = self {
                observer.onNext(self.createAttributedText(with: text, mentionedUsersNames: mentionedUsersNames, style: style))
            }
            
            observer.onCompleted()

            return Disposables.create()
        })
    }
    
    private func createAttributedText(with text: String, mentionedUsersNames: [String], style: MessageViewStyle) -> NSAttributedString {
        let lines = text.components(separatedBy: .newlines)
        let mainAttributedText = NSMutableAttributedString(string: "")
        
        let defaultAttributes: [NSAttributedString.Key : Any] = [.font: style.font,
                                                                 .foregroundColor: style.textColor,
                                                                 .backgroundColor: style.backgroundColor]
        for (index, line) in lines.enumerated() {
            if index > 0 {
                mainAttributedText.append(NSAttributedString(string: "\n"))
            }
            
            if line.isEmpty {
                mainAttributedText.append(NSAttributedString(string: "\n"))
            } else {
                let attributedText = NSMutableAttributedString(string: line, attributes: defaultAttributes)
                addAttributes(to: attributedText, mentionedUsersNames: mentionedUsersNames, style: style)
                mainAttributedText.append(attributedText)
            }
        }
        
        return mainAttributedText
    }
    
    private func addAttributes(to attributedText: NSMutableAttributedString,
                               mentionedUsersNames: [String],
                               style: MessageViewStyle) {
        let text = attributedText.string
        let boldFont = style.font.withTraits(.traitBold)
        
        if !mentionedUsersNames.isEmpty {
            addAttributes(to: attributedText, text: text.lowercased(), for: mentionedUsersNames, attributes: [.font: boldFont])
        }
        
        guard style.markdownEnabled, text.rangeOfCharacter(from: .markdown) != nil else {
            return
        }
        
        // Add Bold.
        addAttributes(to: attributedText, regexKeyChar: "\\*\\*|__", attributes: [.font: boldFont])
        
        // Add Italic.
        addAttributes(to: attributedText, regexKeyChar: "\\*|_", attributes: [.font: style.font.withTraits(.traitItalic)])
        
        // Add Strikethrough.
        addAttributes(to: attributedText, regexKeyChar: "-", attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue,
                                                                          .strikethroughColor: style.textColor])
        
        // Add Code.
        if let font = UIFont.monospaced(size: style.font.pointSize) {
            addAttributes(to: attributedText, regexKeyChar: "`", attributes: [.font: font])
        }
        
        // Add quotes.
        addQuoteAttributes(to: attributedText)
    }
    
    private func addAttributes(to attributedText: NSMutableAttributedString,
                               text: String,
                               for mentionedUsersNames: [String],
                               attributes: [NSAttributedString.Key : Any]) {
        mentionedUsersNames.forEach { name in
            if let range = text.range(of: name.lowercased()) {
                let nsRange = text.nsRange(from: range)
                attributedText.replaceCharacters(in: nsRange, with: name)
                attributedText.addAttributes(attributes, range: nsRange)
                
                // Add a shadow for `@`.
                if let style = style, nsRange.location > 0 {
                    let atRange = NSRange(location: nsRange.location - 1, length: 1)
                    attributedText.addAttributes([.foregroundColor: style.textColor.withAlphaComponent(0.5)], range: atRange)
                }
            }
        }
    }
    
    private func addAttributes(to attributedText: NSMutableAttributedString,
                               regexKeyChar: String,
                               attributes: [NSAttributedString.Key: Any]) {
        guard let regularExpression = try? NSRegularExpression(pattern: "(\\s+|^)(\(regexKeyChar))(.+?)(\\2)", options: []) else {
            return
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
    }
    
    private func addQuoteAttributes(to attributedText: NSMutableAttributedString) {
        guard let style = style,
            attributedText.string.contains(">"),
            let regularExpression = try? NSRegularExpression(pattern: "(^)(\\>)\\s*(.+)($)", options: []) else {
                return
        }
        
        let matches = regularExpression.matches(in: attributedText.string,
                                                options: .withoutAnchoringBounds,
                                                range: NSRange(location: 0, length: attributedText.length))
        
        let attributesForMarker: [NSAttributedString.Key: Any] = [.font: style.font.withTraits(.traitBold),
                                                                  .foregroundColor: style.replyColor]
        
        let attributesForText: [NSAttributedString.Key: Any] = [.font: style.font.withTraits(.traitItalic),
                                                                .foregroundColor: style.textColor.withAlphaComponent(0.7)]
        
        matches.forEach { match in
            attributedText.replaceCharacters(in: match.range(at: 2), with: "|")
            attributedText.addAttributes(attributesForMarker, range: match.range(at: 2))
            attributedText.addAttributes(attributesForText, range: match.range(at: 3))
        }
    }
}
