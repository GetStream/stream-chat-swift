//
//  ComposerViewStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public struct ComposerViewStyle: Hashable {
    public typealias States = [State: Style]
    
    public var font: UIFont
    public var textColor: UIColor
    public var placeholderTextColor: UIColor
    public var backgroundColor: UIColor
    public var cornerRadius: CGFloat
    public var states: [State: Style]
    
    public init(font: UIFont = .chatRegular,
                textColor: UIColor = .black,
                placeholderTextColor: UIColor = .chatGray,
                backgroundColor: UIColor = .clear,
                cornerRadius: CGFloat = .composerCornerRadius,
                states: States = [.active: .init(tintColor: .chatLightBlue, borderWidth: 2),
                                  .edit: .init(tintColor: .chatGreen, borderWidth: 2),
                                  .disabled: .init(tintColor: .chatGray, borderWidth: 2)]) {
        self.font = font
        self.textColor = textColor
        self.placeholderTextColor = placeholderTextColor
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
        hasher.combine(placeholderTextColor)
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
        public let tintColor: UIColor
        public let borderWidth: CGFloat
        
        public init(tintColor: UIColor = .chatGray, borderWidth: CGFloat = 0) {
            self.tintColor = tintColor
            self.borderWidth = borderWidth
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(tintColor)
            hasher.combine(borderWidth)
        }
    }
}
