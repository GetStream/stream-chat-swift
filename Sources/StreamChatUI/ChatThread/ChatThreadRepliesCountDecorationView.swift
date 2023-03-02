//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The date separator view that groups messages from the same day.
open class ChatThreadRepliesCountDecorationView: ChatMessageDecorationView, AppearanceProvider {
    /// The date in string format.
    open var content: String? {
        didSet { updateContentIfNeeded() }
    }

    /// The container that the contentTextLabel will be placed aligned to its centre.
    open private(set) lazy var container: UIView = UIView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "repliesCountDecorationContainer")

    /// The text label that renders the date string.
    open private(set) lazy var textLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "textLabel")

    override open func setUpLayout() {
        super.setUpLayout()

        embed(container, insets: .init(top: 0, leading: 0, bottom: 8, trailing: 0))
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

    override open func updateContent() {
        super.updateContent()

        textLabel.text = content
    }
}
