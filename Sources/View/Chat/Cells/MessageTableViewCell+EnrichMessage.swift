//
//  MessageTableViewCell+EnrichMessage.swift
//  GetStreamChat
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
        let attributedText = NSMutableAttributedString(string: text,
                                                       attributes: [.font: style.font,
                                                                    .foregroundColor: style.textColor,
                                                                    .backgroundColor: style.backgroundColor])
        let boldFont = style.font.withTraits(.traitBold)
        
        if !mentionedUsersNames.isEmpty {
            addAttributes(to: attributedText, text: text, for: mentionedUsersNames, attributes: [.font: boldFont])
        }
        
        guard style.markdownEnabled, text.rangeOfCharacter(from: .markdown) != nil else {
            return attributedText
        }
        
        // Add Bold.
        addAttributes(to: attributedText, regexKeyChar: "*", attributes: [.font: boldFont])
        
        // Add Italic.
        addAttributes(to: attributedText, regexKeyChar: "_", attributes: [.font: style.font.withTraits(.traitItalic)])
        
        // Add Strikethrough.
        addAttributes(to: attributedText, regexKeyChar: "-", attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue,
                                                                          .strikethroughColor: style.textColor])
        
        // Add Code.
        if let font = UIFont.monospaced(size: style.font.pointSize) {
            addAttributes(to: attributedText, regexKeyChar: "`", attributes: [.font: font])
        }
        
        addQuoteAttributes(to: attributedText)
        
        return attributedText
    }
    
    private func addAttributes(to attributedText: NSMutableAttributedString,
                               text: String,
                               for mentionedUsersNames: [String],
                               attributes: [NSAttributedString.Key : Any]) {
        mentionedUsersNames.forEach { name in
            if let range = text.range(of: name) {
                attributedText.addAttributes(attributes, range: text.nsRange(from: range))
            }
        }
    }
    
    private func addAttributes(to attributedText: NSMutableAttributedString,
                               regexKeyChar: String,
                               attributes: [NSAttributedString.Key: Any]) {
        guard attributedText.string.contains(regexKeyChar),
            let regularExpression = try? NSRegularExpression(pattern: "(\\s+|^)(\\\(regexKeyChar))(.+?)(\\2)", options: []) else {
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
            let regularExpression = try? NSRegularExpression(pattern: "(\n|^)(\\>)\\s*(.+)(\n|$)", options: []) else {
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
