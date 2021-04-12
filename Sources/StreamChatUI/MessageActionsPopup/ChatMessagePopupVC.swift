//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `_ChatMessagePopupVC` is shown when user long-presses a message
/// By default, it has a blurred background, reactions, and actions which are shown for a given message
/// and with which user can interact
public typealias ChatMessagePopupVC = _ChatMessagePopupVC<NoExtraData>

/// `_ChatMessagePopupVC` is shown when user long-presses a message
/// By default, it has a blurred background, reactions, and actions which are shown for a given message
/// and with which user can interact
open class _ChatMessagePopupVC<ExtraData: ExtraDataTypes>: _ViewController, UIConfigProvider {
    /// `UIScrollView` for showing content and updating its position via setting its content offset
    open private(set) lazy var scrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
    /// `UIView` embedded in `scrollView`
    open private(set) lazy var scrollContentView = UIView()
        .withoutAutoresizingMaskConstraints
    /// `containerView` encapsulating underlying views `reactionsController`, `actionsController` and `messageContentView`
    open private(set) lazy var containerView = ContainerView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    /// `UIView` with `UIBlurEffect` that is shown as a background
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

    /// New instance of `messageContentViewClass` that is populated with `message` data
    open private(set) lazy var messageContentView = messageContentViewClass.init()
        .withoutAutoresizingMaskConstraints

    /// `messageContentView` class that is populated with `message` and shown
    public var messageContentViewClass: _ChatMessageContentView<ExtraData>.Type!
    /// Message data that is shown
    public var message: _ChatMessageGroupPart<ExtraData>!
    public var messageViewFrame: CGRect!
    public var originalMessageView: UIView!
    public var actionsController: _ChatMessageActionsVC<ExtraData>!
    public var reactionsController: _ChatMessageReactionsVC<ExtraData>?

    // MARK: - Private

    private var actionsView: UIView { actionsController.view }
    private var actionsViewHeight: CGFloat { CGFloat(actionsController.messageActions.count) * 40 }
    private var reactionsView: UIView? { reactionsController?.view }
    private var reactionsViewHeight: CGFloat { reactionsView == nil ? 0 : 40 }
    private var spacing: CGFloat = 8

    // MARK: - Life Cycle

    override open func setUp() {
        super.setUp()
        
        scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnOverlay)))
        scrollView.contentInsetAdjustmentBehavior = .always
        scrollView.isScrollEnabled = false
    }

    override public func defaultAppearance() {
        view.backgroundColor = .clear
        blurView.alpha = 0

        reactionsView?.alpha = 0
        reactionsView?.transform = .init(scaleX: 0.5, y: 0.5)
        
        actionsView.alpha = 0
        actionsView.transform = .init(scaleX: 0.5, y: 0.5)
    }

    override open func setUpLayout() {
        if let reactionsController = reactionsController {
            reactionsController.view.translatesAutoresizingMaskIntoConstraints = false
            addChildViewController(reactionsController, targetView: contentView)
        }

        actionsController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(actionsController, targetView: contentView)

        contentView.addSubview(messageContentView)
        messageContentView.setupMessageBubbleView()
        scrollContentView.addSubview(contentView)
        scrollView.embed(scrollContentView)
        view.embed(blurView)
        view.embed(scrollView)

        var constraints = [
            scrollContentView.widthAnchor.pin(equalTo: view.widthAnchor),
            
            contentView.leadingAnchor.pin(equalTo: scrollContentView.leadingAnchor),
            contentView.trailingAnchor.pin(equalTo: scrollContentView.trailingAnchor),
            
            reactionsView?.heightAnchor.pin(equalToConstant: reactionsViewHeight),
            reactionsView?.topAnchor.pin(equalTo: contentView.topAnchor),
            reactionsView?.leadingAnchor.pin(greaterThanOrEqualTo: contentView.leadingAnchor),
            reactionsView?.trailingAnchor.pin(lessThanOrEqualTo: contentView.trailingAnchor),
            reactionsView?.bottomAnchor.pin(equalTo: messageContentView.topAnchor, constant: -spacing),
            
            messageContentView.topAnchor.pin(equalTo: contentView.topAnchor).almostRequired,
            messageContentView.widthAnchor.pin(equalToConstant: messageViewFrame.width),
            messageContentView.heightAnchor.pin(equalToConstant: messageViewFrame.height),
            
            actionsView.topAnchor.pin(equalTo: messageContentView.bottomAnchor, constant: spacing),
            actionsView.widthAnchor.pin(equalTo: contentView.widthAnchor, multiplier: 0.7),
            actionsView.bottomAnchor.pin(lessThanOrEqualTo: scrollContentView.bottomAnchor)
        ]

        if message.isSentByCurrentUser {
            constraints.append(contentsOf: [
                messageContentView.trailingAnchor.pin(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.maxX
                ),
                actionsView.trailingAnchor.pin(equalTo: messageContentView.trailingAnchor),
                reactionsView?.centerXAnchor.pin(equalTo: messageContentView.leadingAnchor)
                    .with(priority: .defaultHigh),
                reactionsController?.reactionsBubble.tailTrailingAnchor.pin(equalTo: messageContentView.leadingAnchor)
            ])
        } else {
            constraints.append(contentsOf: [
                messageContentView.leadingAnchor.pin(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.minX
                ),
                actionsView.leadingAnchor.pin(equalTo: messageContentView.messageBubbleView!.leadingAnchor),
                reactionsView?.centerXAnchor.pin(equalTo: messageContentView.trailingAnchor)
                    .with(priority: .defaultHigh),
                reactionsController?.reactionsBubble.tailLeadingAnchor.pin(equalTo: messageContentView.trailingAnchor)
            ])
        }

        if messageViewFrame.minY <= 0 {
            constraints.append(contentsOf: [
                contentView.topAnchor.pin(equalTo: scrollContentView.topAnchor),
                contentView.bottomAnchor.pin(
                    equalTo: scrollContentView.bottomAnchor,
                    constant: -(view.bounds.height - messageViewFrame.maxY - actionsViewHeight - spacing)
                )
            ])
        } else {
            constraints.append(contentsOf: [
                contentView.topAnchor.pin(
                    equalTo: scrollContentView.topAnchor,
                    constant: messageViewFrame.minY - reactionsViewHeight - spacing
                ),
                contentView.bottomAnchor.pin(equalTo: scrollContentView.bottomAnchor)
            ])
        }

        NSLayoutConstraint.activate(constraints.compactMap { $0 })
    }

    override open func updateContent() {
        messageContentView.message = message
        messageContentView.reactionsBubble!.isHidden = true
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
                self.scrollToMakeMessageVisible() // Makes the animation look a bit weird, but it's much faster...
                self.blurView.alpha = 1

                self.actionsView.alpha = 1
                self.actionsView.transform = .identity
            }
            
            Animate(delay: 0.1) {
                self.reactionsView?.alpha = 1
                self.reactionsView?.transform = .identity
            }
        }
    }
    
    open func applyInitialContentOffset() {
        let contentOffset = CGPoint(x: 0, y: max(0, -messageViewFrame.minY + spacing + reactionsViewHeight))
        scrollView.setContentOffset(contentOffset, animated: false)
    }

    open func scrollToMakeMessageVisible() {
        let contentRect = scrollContentView.convert(contentView.frame, to: scrollView)
        scrollView.scrollRectToVisible(contentRect, animated: false)
    }

    // MARK: - Actions

    @objc open func didTapOnOverlay() {
        dismiss(animated: true)
    }
}
