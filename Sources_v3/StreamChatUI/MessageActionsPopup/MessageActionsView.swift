//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageActionsView<ExtraData: UIExtraDataTypes>: View, UIConfigProvider {
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
        backgroundColor = .outgoingMessageBubbleBorder
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
            let actionView = uiConfig.messageList.messageActionButton.init()
            actionView.actionItem = $0
            stackView.addArrangedSubview(actionView)
        }
    }
}

// MARK: - Controller

open class ChatMessageActionsViewController<ExtraData: UIExtraDataTypes>: ViewController, UIConfigProvider {
    public var messageActions: [ChatMessageActionItem] = [] {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    private lazy var messageActionView = uiConfig
        .messageList
        .messageActionsView
        .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Life Cycle

    override open func setUpLayout() {
        view.embed(messageActionView)
    }

    override open func updateContent() {
        messageActionView.actionItems = messageActions
    }
}
