//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `ChatMessagePopupVC` is shown when user long-presses a message.
/// By default, it has a blurred background, reactions, and actions which are shown for a given message
/// and with which user can interact.
open class ChatMessagePopupVC: _ViewController, ComponentsProvider {
    /// The scroll view which contains the content view of the popup.
    open private(set) var scrollView = UIScrollView().withoutAutoresizingMaskConstraints

    /// The view that contains all views and is responsible the make the popup view scrollable.
    open private(set) var contentView = UIView().withoutAutoresizingMaskConstraints

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
        
        view.embed(blurView)
        setupScrollView()

        messageContainerStackView.axis = .vertical
        messageContainerStackView.spacing = 8
        contentView.addSubview(messageContainerStackView)

        var constraints: [NSLayoutConstraint] = [
            messageContainerStackView.leadingAnchor.pin(greaterThanOrEqualTo: contentView.leadingAnchor),
            messageContainerStackView.trailingAnchor.pin(lessThanOrEqualTo: contentView.trailingAnchor),
            messageContainerStackView.bottomAnchor.pin(lessThanOrEqualTo: contentView.bottomAnchor)
        ]

        if let reactionsController = reactionsController {
            messageContainerStackView.addArrangedSubview(reactionsContainerView)
            reactionsContainerView.addArrangedSubview(.spacer(axis: .horizontal))
            addChildViewController(reactionsController, targetView: reactionsContainerView)
            
            reactionsContainerView.addArrangedSubview(.spacer(axis: .horizontal))

            if message.isSentByCurrentUser {
                constraints += [
                    reactionsController.view.leadingAnchor.pin(
                        lessThanOrEqualTo: reactionsController.reactionsBubble.tailLeadingAnchor
                    ),
                    reactionsController.reactionsBubble.tailTrailingAnchor.pin(
                        equalTo: messageContentContainerView.leadingAnchor,
                        constant: messageBubbleViewInsets.left
                    )
                ]
            } else {
                constraints += [
                    reactionsController.reactionsBubble.tailLeadingAnchor.pin(
                        equalTo: messageContentContainerView.trailingAnchor,
                        constant: -messageBubbleViewInsets.right
                    )
                ]
            }
        }

        messageContainerStackView.addArrangedSubview(messageContentContainerView)
        constraints += [
            messageContentContainerView.widthAnchor.pin(equalToConstant: messageViewFrame.width),
            messageContentContainerView.heightAnchor.pin(equalToConstant: messageViewFrame.height)
        ]

        if let actionsController = actionsController {
            messageContainerStackView.addArrangedSubview(actionsContainerStackView)
            addChildViewController(actionsController, targetView: actionsContainerStackView)

            constraints += [
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
        }

        if let reactionAuthorsController = reactionAuthorsController {
            addChildViewController(reactionAuthorsController, targetView: messageContainerStackView)

            constraints += [
                reactionAuthorsController.view.heightAnchor.pin(
                    equalToConstant: reactionAuthorsViewHeight
                )
            ]
            constraints += [
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
        }

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

// MARK: Helpers

private extension ChatMessagePopupVC {
    func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.widthAnchor.pin(equalTo: view.widthAnchor),
            scrollView.topAnchor.pin(equalTo: view.topAnchor),
            scrollView.bottomAnchor.pin(equalTo: view.bottomAnchor),
            contentView.widthAnchor.pin(equalTo: scrollView.widthAnchor),
            contentView.topAnchor.pin(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.pin(equalTo: scrollView.bottomAnchor)
        ])
    }
}
