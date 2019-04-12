//
//  ComposerViewStyle.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public struct ComposerViewStyle: Hashable {
    public let font: UIFont
    public let textColor: UIColor
    public let tintColor: UIColor
    public let backgroundColor: UIColor
    public let cornerRadius: CGFloat
    private let states: [State: Style]
    
    init(font: UIFont = .chatRegular,
        textColor: UIColor = .black,
        tintColor: UIColor = .chatGray,
        backgroundColor: UIColor = .chatComposer,
        cornerRadius: CGFloat = .composerCornerRadius,
        states: [State: Style] = [.active: Style(borderWidth: 2),
                                  .disabled: Style(borderWidth: 2, borderColor: .chatGray)]) {
        self.font = font
        self.textColor = textColor
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.states = states
    }
    
    public func style(with state: State) -> Style {
        if let style = states[state] {
            return style
        }
        
        return Style()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(font)
        hasher.combine(textColor)
        hasher.combine(tintColor)
        hasher.combine(backgroundColor)
        hasher.combine(states)
    }
}

extension ComposerViewStyle {
    public enum State: Hashable {
        case normal
        case active
        case edit
        case disabled
    }
    
    public struct Style: Hashable {
        public let borderWidth: CGFloat
        public let borderColor: UIColor
        
        init(borderWidth: CGFloat = 0,
             borderColor: UIColor = .chatBlue) {
            self.borderWidth = borderWidth
            self.borderColor = borderColor
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(borderWidth)
            hasher.combine(borderColor)
        }
    }
}
