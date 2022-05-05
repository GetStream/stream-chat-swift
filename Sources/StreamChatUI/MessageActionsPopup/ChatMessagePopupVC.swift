//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `ChatMessagePopupVC` is shown when user long-presses a message.
/// By default, it has a blurred background, a reactions picker at the top, the message in the center,
/// and at the bottom the message actions sheet or the reaction authors list.
open class ChatMessagePopupVC: _ViewController, ComponentsProvider {
    /// The scroll view which contains the content view of the popup.
    open private(set) var scrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "scrollView")

    /// The view that contains all views and is responsible the make the popup view scrollable.
    open private(set) var contentView = UIView().withoutAutoresizingMaskConstraints
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "contentView")

    /// Container view responsible to layout the main popup views. By default, contains a top view (reactions view),
    /// center view (message view) and bottom view (message actions or reaction authors).
    open private(set) lazy var messageContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "messageContainerStackView")

    /// `UIView` with `UIBlurEffect` that is shown as a background.
    open private(set) lazy var blurView: UIView = {
        let blur: UIBlurEffect
        if #available(iOS 13.0, *) {
            blur = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            blur = UIBlurEffect(style: .regular)
        }
        return UIVisualEffectView(effect: blur)
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "blurView")
    }()
    
    /// Container view that holds `messageContentView`.
    open private(set) lazy var messageContentContainerView = UIView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "messageContentContainerView")

    /// Container that holds `reactionsController` that displays reactions
    open private(set) lazy var reactionsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "reactionsContainerView")

    /// Container that holds actions
    open private(set) var actionsContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "actionsContainerStackView")

    /// Insets for `messageContentView`'s bubble view.
    public var messageBubbleViewInsets: UIEdgeInsets = .zero

    /// `messageContentView` being displayed.
    public var messageContentView: ChatMessageContentView!

    /// Message data that is shown.
    public var message: ChatMessage { messageContentView.content! }
    
    /// Initial frame of a message.
    public var messageViewFrame: CGRect!

    /// `ChatMessageActionsVC` instance for showing actions.
    public var actionsController: ChatMessageActionsVC?

    /// `ChatMessageReactionsVC` instance for showing reactions.
    public var reactionsController: ChatMessageReactionsPickerVC?

    /// `ChatMessageReactionAuthorsVC` instance for showing the authors of the reactions.
    public var reactionAuthorsController: ChatMessageReactionAuthorsVC?

    /// The width percentage of the actions view in relation with the popup's width.
    open var actionsViewWidthMultiplier: CGFloat {
        0.7
    }

    /// The height of the reactions author view. By default it depends on the number of total reactions.
    open var reactionAuthorsViewHeight: CGFloat {
        message.totalReactionsCount > 4 ? 320 : 180
    }

    /// The width percentage of the reactions author view in relation with the popup's width.
    /// By default it depends on the number of total reactions.
    open var reactionAuthorsViewWidthMultiplier: CGFloat {
        message.totalReactionsCount >= 4 ? 0.90 : 0.75
    }

    override open func setUp() {
        super.setUp()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnView))
        tapRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapRecognizer)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        view.backgroundColor = .clear
    }

    override open func setUpLayout() {
        guard messageViewFrame != nil else { return }

        // Add View Hierarchy
        addBlurView()
        addScrollView()
        addContentView()
        addMainContainerView()
        addReactionPickerView()
        addMessageView()
        addMessageActionsView()
        addReactionAuthorsView()

        // Add View Constraints
        layoutMainContainerView()
        layoutReactionPickerView()
        layoutMessageView()
        layoutMessageActionsView()
        layoutReactionAuthorsView()
        layoutPositionOfMessageView()
    }

    /// Add the background blur to the view hierarchy.
    open func addBlurView() {
        view.embed(blurView)
    }

    /// Add the scroll view to the view hierarchy.
    open func addScrollView() {
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.widthAnchor.pin(equalTo: view.widthAnchor),
            scrollView.topAnchor.pin(equalTo: view.topAnchor),
            scrollView.bottomAnchor.pin(equalTo: view.bottomAnchor)
        ])
    }

    /// Add the content view to the view hierarchy.
    open func addContentView() {
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.widthAnchor.pin(equalTo: scrollView.widthAnchor),
            contentView.topAnchor.pin(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.pin(equalTo: scrollView.bottomAnchor)
        ])
    }

    /// Add the main container to the view hierarchy.
    open func addMainContainerView() {
        messageContainerStackView.axis = .vertical
        messageContainerStackView.spacing = 8
        contentView.addSubview(messageContainerStackView)
    }

    /// Add the reaction picker to the view hierarchy.
    open func addReactionPickerView() {
        guard let reactionPicker = reactionsController else { return }
        messageContainerStackView.addArrangedSubview(reactionsContainerView)
        reactionsContainerView.addArrangedSubview(.spacer(axis: .horizontal))
        addChildViewController(reactionPicker, targetView: reactionsContainerView)
        reactionsContainerView.addArrangedSubview(.spacer(axis: .horizontal))
    }

    /// Add the message view to the view hierarchy.
    open func addMessageView() {
        messageContainerStackView.addArrangedSubview(messageContentContainerView)
    }

    /// Add the message actions to the view hierarchy.
    open func addMessageActionsView() {
        guard let actionsController = actionsController else { return }
        messageContainerStackView.addArrangedSubview(actionsContainerStackView)
        addChildViewController(actionsController, targetView: actionsContainerStackView)
    }

    /// Add the reaction authors to the view hierarchy.
    open func addReactionAuthorsView() {
        guard let reactionAuthorsController = reactionAuthorsController else { return }
        addChildViewController(reactionAuthorsController, targetView: messageContainerStackView)
    }

    /// Layouts the main container responsible for stacking all the popup components.
    open func layoutMainContainerView() {
        var constraints: [NSLayoutConstraint] = [
            messageContainerStackView.leadingAnchor.pin(greaterThanOrEqualTo: contentView.leadingAnchor),
            messageContainerStackView.trailingAnchor.pin(lessThanOrEqualTo: contentView.trailingAnchor),
            messageContainerStackView.bottomAnchor.pin(lessThanOrEqualTo: contentView.bottomAnchor)
        ]

        if message.isSentByCurrentUser {
            messageContainerStackView.alignment = .trailing
            constraints += [
                messageContainerStackView.trailingAnchor.pin(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.maxX
                )
            ]
        } else {
            messageContainerStackView.alignment = .leading
            constraints += [
                messageContainerStackView.leadingAnchor.pin(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.minX
                )
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// Layouts the message view, by default, at the center.
    /// The position of the message is calculated in ` layoutPositionOfMessageView()`.
    open func layoutMessageView() {
        NSLayoutConstraint.activate([
            messageContentContainerView.widthAnchor.pin(equalToConstant: messageViewFrame.width),
            messageContentContainerView.heightAnchor.pin(equalToConstant: messageViewFrame.height)
        ])
    }

    /// Layouts the reactions picker view, by default, at the top.
    open func layoutReactionPickerView() {
        guard let reactionPicker = reactionsController else { return }

        var constraints: [NSLayoutConstraint] = []

        if message.isSentByCurrentUser {
            constraints += [
                reactionPicker.view.leadingAnchor.pin(
                    lessThanOrEqualTo: reactionPicker.reactionsBubble.tailLeadingAnchor
                ),
                reactionPicker.reactionsBubble.tailTrailingAnchor.pin(
                    equalTo: messageContentContainerView.leadingAnchor,
                    constant: messageBubbleViewInsets.left
                )
            ]
        } else {
            constraints += [
                reactionPicker.reactionsBubble.tailLeadingAnchor.pin(
                    equalTo: messageContentContainerView.trailingAnchor,
                    constant: -messageBubbleViewInsets.right
                )
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// Layouts the message actions sheet, by default, at the bottom.
    open func layoutMessageActionsView() {
        guard let actionsController = self.actionsController else {
            return
        }

        var constraints: [NSLayoutConstraint] = [
            actionsController.view.widthAnchor.pin(
                equalTo: contentView.widthAnchor,
                multiplier: actionsViewWidthMultiplier
            )
        ]

        if message.isSentByCurrentUser {
            constraints += [
                actionsController.view.trailingAnchor.pin(
                    equalTo: messageContentContainerView.trailingAnchor
                )
            ]
        } else {
            constraints += [
                actionsController.view.leadingAnchor.pin(
                    equalTo: messageContentContainerView.leadingAnchor,
                    constant: messageBubbleViewInsets.left
                )
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// Layouts the reaction authors view, by default, at the bottom. It can display
    /// the message actions instead depending on where the popup is being presented from.
    open func layoutReactionAuthorsView() {
        guard let reactionAuthorsController = self.reactionAuthorsController else {
            return
        }

        var constraints: [NSLayoutConstraint] = [
            reactionAuthorsController.view.heightAnchor.pin(
                equalToConstant: reactionAuthorsViewHeight
            ),
            reactionAuthorsController.view.widthAnchor.pin(
                equalTo: contentView.widthAnchor,
                multiplier: reactionAuthorsViewWidthMultiplier
            )
        ]

        if message.isSentByCurrentUser {
            constraints += [
                reactionAuthorsController.view.trailingAnchor.pin(
                    equalTo: messageContentContainerView.trailingAnchor
                )
            ]
        } else {
            constraints += [
                reactionAuthorsController.view.leadingAnchor.pin(
                    equalTo: messageContentContainerView.leadingAnchor,
                    constant: messageBubbleViewInsets.left
                )
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// Calculates where the message view should be displayed, preferably in the same
    /// coordinates of the original message, but if not possible it will adjust to fit the screen.
    open func layoutPositionOfMessageView() {
        var constraints: [NSLayoutConstraint] = []

        reactionsController?.view.layoutIfNeeded()
        reactionAuthorsController?.view.layoutIfNeeded()
        actionsController?.view.layoutIfNeeded()

        let reactionsPickerHeight = reactionsController?.view.frame.height ?? 0
        let bottomViewHeight = actionsController?.view.frame.height ?? reactionAuthorsViewHeight
        let messageViewHeight = messageViewFrame.height
        let popupHeight = reactionsPickerHeight + bottomViewHeight + messageViewHeight

        let shouldPinToTop = messageViewFrame.minY <= 0 || popupHeight >= view.frame.height
        let margin: CGFloat = 20

        if shouldPinToTop {
            // When the message is below navigation bar or the popup view
            // requires scroll view, pin the message view to the top.
            let topView = reactionsController?.view ?? messageContentContainerView
            constraints += [
                topView.topAnchor.pin(equalTo: contentView.topAnchor, constant: margin),
                messageContainerStackView.topAnchor.pin(equalTo: contentView.topAnchor)
            ]
        } else {
            // If the message doesn't require scroll view, open the popup view
            // in the same coordinates of the original message (from the message list)
            constraints += [
                scrollView.topAnchor
                    .pin(equalTo: view.safeAreaLayoutGuide.topAnchor)
                    .with(priority: .streamRequire),
                messageContentContainerView.topAnchor
                    .pin(equalTo: contentView.topAnchor, constant: messageViewFrame.minY)
                    .with(priority: .streamLow)
            ]
            // but don't let the bottom view go below the screen,
            // in that case the original coordinates are ignored.
            constraints += [
                messageContainerStackView.bottomAnchor
                    .pin(lessThanOrEqualTo: view.bottomAnchor, constant: -margin)
                    .with(priority: .streamRequire)
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// Triggered when `view` is tapped.
    @objc open func didTapOnView(_ gesture: UITapGestureRecognizer) {
        let actionsLocation = gesture.location(in: actionsController?.view)
        let reactionsLocation = gesture.location(in: reactionsController?.view)
        let isGestureInActionsView = actionsController?.view.frame.contains(actionsLocation) == true
        let isGestureInReactionsView = reactionsController?.view.frame.contains(reactionsLocation) == true

        if isGestureInActionsView || isGestureInReactionsView {
            return
        }

        dismiss(animated: true)
    }
}
