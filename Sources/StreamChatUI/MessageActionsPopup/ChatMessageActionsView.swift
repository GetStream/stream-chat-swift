//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageActionsView = _ChatMessageActionsView<NoExtraData>

internal class _ChatMessageActionsView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    internal var actionItems: [ChatMessageActionItem<ExtraData>] = [] {
        didSet { updateContentIfNeeded() }
    }

    // MARK: Subviews

    internal private(set) lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 1
        return stackView.withoutAutoresizingMaskConstraints
    }()

    // MARK: Overrides

    override internal func defaultAppearance() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        backgroundColor = uiConfig.colorPalette.border
    }

    override internal func setUpLayout() {
        embed(stackView)
    }

    override internal func updateContent() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
            stackView.removeArrangedSubview($0)
        }

        actionItems.forEach {
            let actionView = uiConfig.messageList.messageActionsSubviews.actionButton.init()
            actionView.actionItem = $0
            stackView.addArrangedSubview(actionView)
        }
    }
}
