//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view used to show a separator when there are unread messages.
open class ChatMessagesCountDecorationView: ChatMessageDecorationView, AppearanceProvider {
    /// The container that the contentTextLabel will be placed aligned to its centre.
    open private(set) lazy var container: UIView = UIView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "messagesCountDecorationView")

    /// The text label that renders the date string.
    open private(set) lazy var textLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "textLabel")

    override open func setUpLayout() {
        super.setUpLayout()

        embed(container)
        container.embed(textLabel, insets: .init(top: 3, leading: 9, bottom: 3, trailing: 9))
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        container.backgroundColor = appearance.colorPalette.background6

        textLabel.font = appearance.fonts.caption1.bold
        textLabel.textColor = appearance.colorPalette.textLowEmphasis
        textLabel.textAlignment = .center
    }
}
