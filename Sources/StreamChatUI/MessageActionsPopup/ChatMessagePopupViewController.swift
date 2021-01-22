//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessagePopupViewController<ExtraData: ExtraDataTypes>: ViewController, UIConfigProvider {
    public private(set) lazy var scrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
    public private(set) lazy var scrollContentView = UIView()
        .withoutAutoresizingMaskConstraints
    public private(set) lazy var contentView = UIView()
        .withoutAutoresizingMaskConstraints
    public private(set) lazy var blurView: UIView = {
        let blur: UIBlurEffect
        if #available(iOS 13.0, *) {
            blur = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            blur = UIBlurEffect(style: .regular)
        }
        return UIVisualEffectView(effect: blur)
            .withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var messageContentView = uiConfig.messageList.messageContentView.init()
        .withoutAutoresizingMaskConstraints

    public var message: _ChatMessageGroupPart<ExtraData>!
    public var messageViewFrame: CGRect!
    public var actionsController: ChatMessageActionsVC<ExtraData>!
    public var reactionsController: ChatMessageReactionVC<ExtraData>?

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
    }

    override open func setUpLayout() {
        if let reactionsController = reactionsController {
            reactionsController.view.translatesAutoresizingMaskIntoConstraints = false
            addChildViewController(reactionsController, targetView: contentView)
        }

        actionsController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(actionsController, targetView: contentView)

        contentView.addSubview(messageContentView)
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
                actionsView.leadingAnchor.pin(equalTo: messageContentView.messageBubbleView.leadingAnchor),
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
        messageContentView.reactionsBubble.isHidden = true
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
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scrollToMakeMessageVisible()
    }

    open func applyInitialContentOffset() {
        let contentOffset = CGPoint(x: 0, y: max(0, -messageViewFrame.minY + spacing + reactionsViewHeight))
        scrollView.setContentOffset(contentOffset, animated: false)
    }

    open func scrollToMakeMessageVisible() {
        let contentRect = scrollContentView.convert(contentView.frame, to: scrollView)
        scrollView.scrollRectToVisible(contentRect, animated: true)
    }

    // MARK: - Actions

    @objc open func didTapOnOverlay() {
        dismiss(animated: true)
    }
}
