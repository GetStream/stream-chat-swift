//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessagePopupViewController<ExtraData: ExtraDataTypes>: ViewController, UIConfigProvider {
    public private(set) lazy var scrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
    public private(set) lazy var scrollContentView = UIView()
        .withoutAutoresizingMaskConstraints
    public private(set) lazy var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        .withoutAutoresizingMaskConstraints
    public private(set) lazy var messageContentView = uiConfig.messageList.messageContentView.init()
        .withoutAutoresizingMaskConstraints

    public var message: _ChatMessageGroupPart<ExtraData>!
    public var messageViewFrame: CGRect!
    public var actionsController: ChatMessageActionsVC<ExtraData>!
    public var reactionsController: ChatMessageReactionViewController<ExtraData>?

    // MARK: - Life Cycle

    override open func setUp() {
        super.setUp()
        
        scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnOverlay)))
    }

    override public func defaultAppearance() {
        view.backgroundColor = uiConfig.colorPalette.popupDimmedBackground
    }

    override open func setUpLayout() {
        if let reactionsController = reactionsController {
            reactionsController.view.translatesAutoresizingMaskIntoConstraints = false
            addChildViewController(reactionsController, targetView: scrollContentView)
        }

        actionsController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(actionsController, targetView: scrollContentView)

        scrollContentView.addSubview(messageContentView)
        scrollView.embed(scrollContentView)
        view.embed(blurView)
        view.embed(scrollView)

        var constraints = [
            scrollContentView.widthAnchor.constraint(equalTo: view.widthAnchor),
            scrollContentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor),
            
            messageContentView.bottomAnchor.constraint(equalTo: scrollContentView.topAnchor, constant: messageViewFrame.maxY),
            messageContentView.widthAnchor.constraint(equalToConstant: messageViewFrame.width),
            
            reactionsController?.view.bottomAnchor.constraint(
                equalTo: messageContentView.messageBubbleView.topAnchor,
                constant: -8
            ),
            reactionsController?.view.leadingAnchor.constraint(greaterThanOrEqualTo: scrollContentView.leadingAnchor),
            reactionsController?.view.trailingAnchor.constraint(lessThanOrEqualTo: scrollContentView.trailingAnchor),
            
            actionsController.view.topAnchor.constraint(equalToSystemSpacingBelow: messageContentView.bottomAnchor, multiplier: 1),
            actionsController.view.widthAnchor.constraint(equalTo: scrollContentView.widthAnchor, multiplier: 0.7),
            actionsController.view.bottomAnchor.constraint(lessThanOrEqualTo: scrollContentView.bottomAnchor)
        ]

        if message.isSentByCurrentUser == true {
            constraints.append(contentsOf: [
                messageContentView.trailingAnchor.constraint(
                    equalTo: scrollContentView.trailingAnchor,
                    constant: messageViewFrame.maxX - UIScreen.main.bounds.width
                ),
                actionsController.view.trailingAnchor.constraint(equalTo: messageContentView.trailingAnchor),
                reactionsController?.view.centerXAnchor.constraint(equalTo: messageContentView.leadingAnchor)
            ])
        } else {
            constraints.append(contentsOf: [
                messageContentView.leadingAnchor.constraint(
                    equalTo: scrollContentView.leadingAnchor,
                    constant: messageViewFrame.minX
                ),
                actionsController.view.leadingAnchor.constraint(equalTo: messageContentView.messageBubbleView.leadingAnchor),
                reactionsController?.view.centerXAnchor.constraint(equalTo: messageContentView.trailingAnchor)
            ])
        }

        constraints.last??.priority = .defaultHigh
        NSLayoutConstraint.activate(constraints.compactMap { $0 })
    }

    override open func updateContent() {
        messageContentView.message = message
        messageContentView.messageReactionsView.isHidden = true
    }

    // MARK: - Actions

    @objc open func didTapOnOverlay() {
        dismiss(animated: true)
    }
}
