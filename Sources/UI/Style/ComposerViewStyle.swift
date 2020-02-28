//
//  ComposerViewStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A composer style.
public struct ComposerViewStyle {
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
    /// Placeholder text
    public var placeholderText: String
    /// A placeholder text color.
    public var placeholderTextColor: UIColor
    /// A background color.
    public var backgroundColor: UIColor
    /// A background color for a helper container, e.g. att attachments menu, commands suggestions.
    public var helperContainerBackgroundColor: UIColor
    /// A corner radius.
    public var cornerRadius: CGFloat
    /// A composer height.
    public var height: CGFloat
    /// Edge insets.
    public var edgeInsets: UIEdgeInsets
    /// A send button visibility.
    public var sendButtonVisibility: ChatViewStyleVisibility
    
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
                placeholderText: String = "Write a message",
                placeholderTextColor: UIColor = .chatGray,
                backgroundColor: UIColor = .clear,
                helperContainerBackgroundColor: UIColor = .white,
                cornerRadius: CGFloat = .composerCornerRadius,
                height: CGFloat = .composerHeight,
                edgeInsets: UIEdgeInsets = .all(.messageEdgePadding),
                sendButtonVisibility: ChatViewStyleVisibility = .whenActive,
                states: States = [.active: .init(tintColor: .chatLightBlue, borderWidth: 2),
                                  .edit: .init(tintColor: .chatGreen, borderWidth: 2),
                                  .disabled: .init(tintColor: .chatGray, borderWidth: 2)]) {
        self.font = font
        self.textColor = textColor
        self.placeholderText = placeholderText
        self.placeholderTextColor = placeholderTextColor
        self.backgroundColor = backgroundColor
        self.helperContainerBackgroundColor = helperContainerBackgroundColor
        self.cornerRadius = cornerRadius
        self.height = height
        self.edgeInsets = edgeInsets
        self.sendButtonVisibility = sendButtonVisibility
        self.states = states
    }
    
    /// A composer style for a state.
    /// - Parameter state: a composer state.
    /// - Returns: a composer state style.
    public func style(with state: State) -> Style {
        states[state, default: Style()]
    }
}

extension ComposerViewStyle {
    /// A composer state.
    public enum State: Hashable {
        /// A composer view style state.
        case normal, active, edit, disabled
    }
    
    /// A composer style.
    public struct Style: Hashable {
        /// A tint color. Also used as border color.
        public var tintColor: UIColor
        /// A border width.
        public var borderWidth: CGFloat
        
        /// Init a cosposerty state style.
        /// - Parameters:
        ///   - tintColor: a tint color.
        ///   - borderWidth: a border width.
        public init(tintColor: UIColor = .chatGray, borderWidth: CGFloat = 0) {
            self.tintColor = tintColor
            self.borderWidth = borderWidth
        }
        
        public static func == (lhs: Style, rhs: Style) -> Bool {
            lhs.tintColor == rhs.tintColor && lhs.borderWidth == rhs.borderWidth
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(tintColor)
            hasher.combine(borderWidth)
        }
    }
}

extension ComposerViewStyle: Hashable {
    
    public static func == (lhs: ComposerViewStyle, rhs: ComposerViewStyle) -> Bool {
        lhs.font == rhs.font
            && lhs.textColor == rhs.textColor
            && lhs.placeholderTextColor == rhs.placeholderTextColor
            && lhs.backgroundColor == rhs.backgroundColor
            && lhs.cornerRadius == rhs.cornerRadius
            && lhs.states == rhs.states
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(font)
        hasher.combine(textColor)
        hasher.combine(placeholderTextColor)
        hasher.combine(backgroundColor)
        hasher.combine(cornerRadius)
        hasher.combine(states)
    }
}
