//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerSuggestionsCommandsReusableView =
    _ChatMessageComposerSuggestionsCommandsReusableView<NoExtraData>

open class _ChatMessageComposerSuggestionsCommandsReusableView<ExtraData: ExtraDataTypes>: UICollectionReusableView,
    UIConfigProvider {
    class var reuseId: String { String(describing: self) }

    public lazy var suggestionsHeader: _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData> = {
        let header = uiConfig.messageComposer.suggestionsHeaderView.init().withoutAutoresizingMaskConstraints
        embed(header)
        return header
    }()
}

public typealias ChatMessageComposerSuggestionsCommandsHeaderView = _ChatMessageComposerSuggestionsCommandsHeaderView<NoExtraData>

open class _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public private(set) lazy var commandImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var headerLabel = UILabel()
        .withoutAutoresizingMaskConstraints

    override public func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.popupBackground

        headerLabel.font = uiConfig.font.body
        headerLabel.textColor = uiConfig.colorPalette.subtitleText
        commandImageView.contentMode = .scaleAspectFit
    }

    override open func setUpLayout() {
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
