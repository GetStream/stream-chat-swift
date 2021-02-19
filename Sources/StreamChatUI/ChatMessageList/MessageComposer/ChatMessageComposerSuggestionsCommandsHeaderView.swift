//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The header reusable view of the suggestion collection view.
internal typealias ChatMessageComposerSuggestionsCommandsReusableView =
    _ChatMessageComposerSuggestionsCommandsReusableView<NoExtraData>

/// The header reusable view of the suggestion collection view.
internal class _ChatMessageComposerSuggestionsCommandsReusableView<ExtraData: ExtraDataTypes>: UICollectionReusableView,
    UIConfigProvider {
    /// The reuse identifier of the reusable header view.
    internal class var reuseId: String { String(describing: self) }
    
    /// The suggestions header view.
    internal lazy var suggestionsHeader: _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData> = {
        let header = uiConfig.messageComposer.suggestionsHeaderView.init().withoutAutoresizingMaskConstraints
        embed(header)
        return header
    }()
}

/// The header view of the suggestion collection view.
internal typealias ChatMessageComposerSuggestionsCommandsHeaderView = _ChatMessageComposerSuggestionsCommandsHeaderView<NoExtraData>

/// The header view of the suggestion collection view.
internal class _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    /// The image icon of the commands header view.
    internal private(set) lazy var commandImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    /// The text label of the commands header view.
    internal private(set) lazy var headerLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport

    override internal func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.popoverBackground

        headerLabel.font = uiConfig.fonts.body
        headerLabel.textColor = uiConfig.colorPalette.subtitleText
        commandImageView.contentMode = .scaleAspectFit
    }

    override internal func setUpLayout() {
        let view = UIView().withoutAutoresizingMaskConstraints
        embed(view, insets: directionalLayoutMargins)

        view.addSubview(commandImageView)
        view.addSubview(headerLabel)
        commandImageView.pin(anchors: [.leading], to: view)
        commandImageView.pin(anchors: [.centerY], to: view)

        NSLayoutConstraint.activate(
            [
                commandImageView.centerYAnchor.pin(equalTo: headerLabel.centerYAnchor),
                headerLabel.centerYAnchor.pin(equalTo: commandImageView.centerYAnchor),
                headerLabel.leadingAnchor.pin(
                    equalToSystemSpacingAfter: commandImageView.trailingAnchor,
                    multiplier: 2
                )
            ]
        )
    }
}
