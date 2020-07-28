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
    /// A reply in the channel view style.
    /// - Note: Set it to nil to disable this feature.
    public var replyInChannelViewStyle: ReplyInChannelViewStyle?
    
    /// A pin style to setup `ComposerView` presentation over messages.
    public var pinStyle: PinStyle
    
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
    ///   - replyInChannelViewStyle: a reply in the channel view style. Set it to nil to disable this feature.
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
                replyInChannelViewStyle: ReplyInChannelViewStyle? = .init(color: .chatGray, selectedColor: .black),
                pinStyle: PinStyle = .floating,
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
        self.replyInChannelViewStyle = replyInChannelViewStyle
        self.pinStyle = pinStyle
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
    }
    
    /// A pin style to setup `ComposerView` presentation over messages.
    public enum PinStyle {
        /// Shows `ComposerView` over messages. It's by default.
        case floating
        /// Shows messages above `ComposerView` with a `ComposerViewStyle` top edge inset.
        case solid
    }
}

extension ComposerViewStyle {
    public struct ReplyInChannelViewStyle: Hashable {
        /// A default button text.
        public static let defaultText = "Also send to the channel"
        
        /// A text for the button.
        public var text: String
        /// A button font.
        public var font: UIFont
        /// A default text color.
        public var color: UIColor
        /// A text color when the checkmark is selected.
        public var selectedColor: UIColor
        /// A button height.
        public var height: CGFloat
        /// Edge insets. The button is pinned to the bottom and left part of `ComposerView`.
        public var edgeInsets: UIEdgeInsets
        
        /// A reply in the channel button style for the `ComposerView`.
        /// - Parameters:
        ///   - text: a text for the button.
        ///   - font: a button font.
        ///   - color: a default text color.
        ///   - selectedColor: a text color when the checkmark is selected.
        ///   - height: a button height.
        ///   - edgeInsets: edge insets. The button is pinned to the bottom and left part of `ComposerView`.
        public init(text: String = ReplyInChannelViewStyle.defaultText,
                    font: UIFont = .chatMedium,
                    color: UIColor,
                    selectedColor: UIColor,
                    height: CGFloat = .composerReplyInChannelHeight,
                    edgeInsets: UIEdgeInsets = .init(top: 0, left: .composerCornerRadius, bottom: -.messageEdgePadding, right: 0)) {
            self.text = text
            self.font = font
            self.color = color
            self.selectedColor = selectedColor
            self.height = height
            self.edgeInsets = edgeInsets
        }
    }
}
