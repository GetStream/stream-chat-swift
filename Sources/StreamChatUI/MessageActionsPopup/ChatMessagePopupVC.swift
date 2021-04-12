//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `_ChatMessagePopupVC` is shown when user long-presses a message.
/// By default, it has a blurred background, reactions, and actions which are shown for a given message
/// and with which user can interact.
public typealias ChatMessagePopupVC = _ChatMessagePopupVC<NoExtraData>

/// `_ChatMessagePopupVC` is shown when user long-presses a message.
/// By default, it has a blurred background, reactions, and actions which are shown for a given message
/// and with which user can interact.
open class _ChatMessagePopupVC<ExtraData: ExtraDataTypes>: _ViewController, UIConfigProvider {
    /// `UIScrollView` for showing content and updating its position via setting its content offset.
    open private(set) lazy var scrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
    /// `UIView` embedded in `scrollView`.
    open private(set) lazy var scrollContentView = UIView()
        .withoutAutoresizingMaskConstraints
    /// `ContainerStackView` encapsulating underlying views `reactionsController`, `actionsController` and `messageContentView`.
    open private(set) lazy var messageContainerStackView = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
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
    }()

    /// New instance of `messageContentViewClass` that is populated with `message` data.
    open private(set) lazy var messageContentView = messageContentViewClass.init()
        .withoutAutoresizingMaskConstraints

    /// `messageContentView` class that is populated with `message` and shown.
    public var messageContentViewClass: _ChatMessageContentView<ExtraData>.Type!
    /// Message data that is shown.
    public var message: _ChatMessageGroupPart<ExtraData>!
    /// Initial frame of a message.
    public var messageViewFrame: CGRect!
    /// `_ChatMessageActionsVC` instance for showing actions.
    public var actionsController: _ChatMessageActionsVC<ExtraData>!
    /// `_ChatMessageReactionsVC` instance for showing reactions.
    public var reactionsController: _ChatMessageReactionsVC<ExtraData>?

    override open func setUp() {
        super.setUp()
        
        scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnOverlay)))
        scrollView.contentInsetAdjustmentBehavior = .always
        scrollView.isScrollEnabled = false
    }

    override public func defaultAppearance() {
        super.defaultAppearance()
        view.backgroundColor = .clear
    }

    override open func setUpLayout() {
        messageContentView.setupMessageBubbleView()
        scrollView.embed(scrollContentView)
        view.embed(blurView)
        view.embed(scrollView)

        messageContainerStackView.spacing = 8
        scrollContentView.addSubview(messageContainerStackView)

        var constraints: [NSLayoutConstraint] = [
            messageContainerStackView.leadingAnchor.pin(greaterThanOrEqualTo: scrollContentView.leadingAnchor),
            messageContainerStackView.trailingAnchor.pin(lessThanOrEqualTo: scrollContentView.trailingAnchor)
        ]

        if let reactionsController = reactionsController {
            let reactionsContainerView = ContainerStackView()
            messageContainerStackView.addArrangedSubview(reactionsContainerView)
            reactionsContainerView.addArrangedSubview(.spacer(axis: .horizontal))
            
            reactionsController.view.translatesAutoresizingMaskIntoConstraints = false
            addChildViewController(reactionsController, targetView: reactionsContainerView)
            
            reactionsContainerView.addArrangedSubview(.spacer(axis: .horizontal))
            
            if message.isSentByCurrentUser {
                constraints += [
                    reactionsController.view.leadingAnchor
                        .pin(lessThanOrEqualTo: reactionsController.reactionsBubble.tailLeadingAnchor),
                    reactionsController.reactionsBubble.tailTrailingAnchor
                        .pin(equalTo: messageContentView.messageBubbleView!.leadingAnchor)
                ]
            } else {
                constraints += [
                    reactionsController.reactionsBubble.tailLeadingAnchor
                        .pin(equalTo: messageContentView.messageBubbleView!.trailingAnchor)
                ]
            }
        }
        
        constraints.append(
            actionsController.view.widthAnchor.pin(equalTo: scrollContentView.widthAnchor, multiplier: 0.7)
        )
        
        messageContainerStackView.addArrangedSubview(messageContentView)
        constraints.append(
            messageContentView.widthAnchor.pin(equalToConstant: messageViewFrame.width)
        )

        let actionsContainerStackView = ContainerStackView()
        actionsContainerStackView.addArrangedSubview(.spacer(axis: .horizontal))
        messageContainerStackView.addArrangedSubview(actionsContainerStackView)
        
        actionsController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(actionsController, targetView: actionsContainerStackView)

        if message.isSentByCurrentUser {
            constraints.append(
                actionsController.view.trailingAnchor.pin(equalTo: messageContentView.trailingAnchor)
            )
        } else {
            constraints.append(
                actionsController.view.leadingAnchor.pin(equalTo: messageContentView.messageBubbleView!.leadingAnchor)
            )
        }
        
        if message.isSentByCurrentUser {
            messageContainerStackView.alignment = .axisTrailing
            constraints.append(
                messageContainerStackView.trailingAnchor.pin(
                    equalTo: scrollContentView.leadingAnchor,
                    constant: messageViewFrame.maxX
                )
            )
        } else {
            messageContainerStackView.alignment = .axisLeading
            constraints.append(
                messageContainerStackView.leadingAnchor.pin(
                    equalTo: scrollContentView.leadingAnchor,
                    constant: messageViewFrame.minX
                )
            )
        }

        constraints.append(
            scrollContentView.widthAnchor.pin(equalTo: view.widthAnchor)
        )

        if messageViewFrame.minY <= 0 {
            constraints += [
                messageContainerStackView.topAnchor.pin(equalTo: scrollContentView.topAnchor),
                (reactionsController?.view ?? messageContentView).topAnchor
                    .pin(equalTo: scrollContentView.topAnchor)
            ]
        } else {
            reactionsController?.view.layoutIfNeeded()
            constraints += [
                messageContentView.topAnchor.pin(
                    equalTo: scrollContentView.topAnchor,
                    constant: messageViewFrame.minY
                ),
                messageContainerStackView.bottomAnchor.pin(equalTo: scrollContentView.bottomAnchor)
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    override open func updateContent() {
        messageContentView.message = message
        messageContentView.reactionsBubble?.isHidden = true
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Initial values for the animation
        blurView.alpha = 0

        reactionsController?.view.alpha = 0
        reactionsController?.view.transform = .init(scaleX: 0.5, y: 0.5)

        actionsController.view.alpha = 0
        actionsController.view.transform = .init(scaleX: 0.5, y: 0.5)
        
        // Initially, the `applyInitialContentOffset` invocation was in `viewDidLayoutSubviews`
        // since the content offset can be applied when all the views are laid out
        // and `scrollView` content size is calculated.
        //
        // The problem is that `viewDidLayoutSubviews` is also called when reaction is
        // added/removed OR the gif is loaded while the initial `contentOffset` should be applied just once.
        //
        // Dispatching the invocation from `viewWillAppear`:
        //  1. makes sure we do it once;
        //  2. postpones it to the next run-loop iteration which guarantees it happens after `viewDidLayoutSubviews`
        DispatchQueue.main.async {
            self.applyInitialContentOffset()
            
            Animate {
                self.scrollToMakeMessageVisible()
                self.blurView.alpha = 1

                self.actionsController.view.alpha = 1
                self.actionsController.view.transform = .identity
            }
            
            Animate(delay: 0.1) {
                self.reactionsController?.view.alpha = 1
                self.reactionsController?.view.transform = .identity
            }
        }
    }
    
    /// Computes initial content offset of `scrollView` for initial possition of its contents.
    open func applyInitialContentOffset() {
        let contentOffset = CGPoint(
            x: 0,
            y: max(
                0,
                -messageViewFrame.minY + ((reactionsController?.view.frame.origin.y ?? 0) - messageContentView.frame.origin.y)
            )
        )
        scrollView.setContentOffset(contentOffset, animated: false)
    }

    /// Updates`scrollView.contentOffset`, so that `containerView` si visible.
    open func scrollToMakeMessageVisible() {
        let contentRect = scrollContentView.convert(messageContainerStackView.frame, to: scrollView)
        scrollView.scrollRectToVisible(contentRect, animated: false)
    }

    /// Triggered when `blurView` is tapped.
    @objc open func didTapOnOverlay() {
        dismiss(animated: true)
    }
}
