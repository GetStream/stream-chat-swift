//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageActionsView = _ChatMessageActionsView<NoExtraData>

open class _ChatMessageActionsView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    public var actionItems: [ChatMessageActionItem<ExtraData>] = [] {
        didSet { updateContentIfNeeded() }
    }

    // MARK: Subviews

    public private(set) lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 1
        return stackView.withoutAutoresizingMaskConstraints
    }()

    // MARK: Overrides

    override public func defaultAppearance() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        backgroundColor = uiConfig.colorPalette.border
    }

    override open func setUpLayout() {
        embed(stackView)
    }

    override open func updateContent() {
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
