//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerSuggestionsCommandsReusableView =
    _ChatMessageComposerSuggestionsCommandsReusableView<NoExtraData>

internal class _ChatMessageComposerSuggestionsCommandsReusableView<ExtraData: ExtraDataTypes>: UICollectionReusableView,
    UIConfigProvider {
    class var reuseId: String { String(describing: self) }

    internal lazy var suggestionsHeader: _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData> = {
        let header = uiConfig.messageComposer.suggestionsHeaderView.init().withoutAutoresizingMaskConstraints
        embed(header)
        return header
    }()
}

internal typealias ChatMessageComposerSuggestionsCommandsHeaderView = _ChatMessageComposerSuggestionsCommandsHeaderView<NoExtraData>

internal class _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    internal private(set) lazy var commandImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    internal private(set) lazy var headerLabel = UILabel()
        .withoutAutoresizingMaskConstraints

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
