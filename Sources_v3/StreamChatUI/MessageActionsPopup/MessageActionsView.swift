//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageActionsView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var actionItems: [ChatMessageActionItem] = [] {
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

    override open func defaultAppearance() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        backgroundColor = uiConfig.colorPalette.outgoingMessageBubbleBorder
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
