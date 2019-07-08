//
//  ComposerViewStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A composer style.
public struct ComposerViewStyle: Hashable {
    /// A composer states type.
    ///
    /// For example:
    /// ```
    /// [.active: .init(tintColor: .chatLightBlue, borderWidth: 2),
    ///  .edit: .init(tintColor: .chatGreen, borderWidth: 2),
    ///  .disabled: .init(tintColor: .chatGray, borderWidth: 2)]
    /// ```
    public typealias States = [State: Style]
    
    /// A font.
    public var font: UIFont
    /// A text color.
    public var textColor: UIColor
    /// A placeholder text color.
    public var placeholderTextColor: UIColor
    /// A background color.
    public var backgroundColor: UIColor
    /// A corner radius.
    public var cornerRadius: CGFloat
    
    /// Composer states.
    ///
    /// For example:
    /// ```
    /// [.active: .init(tintColor: .chatLightBlue, borderWidth: 2),
    ///  .edit: .init(tintColor: .chatGreen, borderWidth: 2),
    ///  .disabled: .init(tintColor: .chatGray, borderWidth: 2)]
    /// ```
    public var states: [State: Style]
    
    
    /// Init a composer style.
    ///
    /// - Parameters:
    ///   - font: a font.
    ///   - textColor: a text color.
    ///   - placeholderTextColor: a placeholder text color.
    ///   - backgroundColor: a background color.
    ///   - cornerRadius: a corner radius.
    ///   - states: composer states (see `States`).
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
    
    /// A composer style for a state.
    ///
    /// - Parameter state: a composer state.
    /// - Returns: a composer state style.
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
    /// A composer state.
    public enum State: Hashable {
        case normal
        case active
        case edit
        case disabled
    }
    
    /// A composer style.
    public struct Style: Hashable {
        /// A tint color.
        public let tintColor: UIColor
        /// A border width.
        public let borderWidth: CGFloat
        
        /// Init a cosposerty state style.
        ///
        /// - Parameters:
        ///   - tintColor: a tint color.
        ///   - borderWidth: a border width.
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
