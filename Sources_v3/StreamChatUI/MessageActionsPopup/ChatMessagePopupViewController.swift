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
            scrollContentView.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            contentView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
            
            reactionsView?.heightAnchor.constraint(equalToConstant: 40),
            reactionsView?.topAnchor.constraint(equalTo: contentView.topAnchor),
            reactionsView?.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            reactionsView?.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            reactionsView?.bottomAnchor.constraint(equalTo: messageContentView.topAnchor, constant: -spacing),
            
            messageContentView.topAnchor.constraint(equalTo: contentView.topAnchor).almostRequired,
            messageContentView.widthAnchor.constraint(equalToConstant: messageViewFrame.width),
            messageContentView.heightAnchor.constraint(equalToConstant: messageViewFrame.height),
            
            actionsView.topAnchor.constraint(equalTo: messageContentView.bottomAnchor, constant: spacing),
            actionsView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
            actionsView.bottomAnchor.constraint(lessThanOrEqualTo: scrollContentView.bottomAnchor)
        ]

        if message.isSentByCurrentUser {
            constraints.append(contentsOf: [
                messageContentView.trailingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.maxX
                ),
                actionsView.trailingAnchor.constraint(equalTo: messageContentView.trailingAnchor),
                reactionsView?.centerXAnchor.constraint(equalTo: messageContentView.leadingAnchor)
                    .with(priority: .defaultHigh),
                reactionsController?.reactionsBubble.tailTrailingAnchor.constraint(equalTo: messageContentView.leadingAnchor)
            ])
        } else {
            constraints.append(contentsOf: [
                messageContentView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.minX
                ),
                actionsView.leadingAnchor.constraint(equalTo: messageContentView.messageBubbleView.leadingAnchor),
                reactionsView?.centerXAnchor.constraint(equalTo: messageContentView.trailingAnchor)
                    .with(priority: .defaultHigh),
                reactionsController?.reactionsBubble.tailLeadingAnchor.constraint(equalTo: messageContentView.trailingAnchor)
            ])
        }

        if messageViewFrame.minY <= 0 {
            constraints.append(contentsOf: [
                contentView.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
                contentView.bottomAnchor.constraint(
                    equalTo: scrollContentView.bottomAnchor,
                    constant: -(view.bounds.height - messageViewFrame.maxY - actionsViewHeight - spacing)
                )
            ])
        } else {
            constraints.append(contentsOf: [
                contentView.topAnchor.constraint(
                    equalTo: scrollContentView.topAnchor,
                    constant: messageViewFrame.minY - reactionsViewHeight - spacing
                ),
                contentView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor)
            ])
        }

        NSLayoutConstraint.activate(constraints.compactMap { $0 })
    }

    override open func updateContent() {
        messageContentView.message = message
        messageContentView.reactionsBubble.isHidden = true
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let contentOffset = CGPoint(x: 0, y: max(0, -messageViewFrame.minY + spacing + reactionsViewHeight))
        scrollView.setContentOffset(contentOffset, animated: false)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let contentRect = scrollContentView.convert(contentView.frame, to: scrollView)
        scrollView.scrollRectToVisible(contentRect, animated: true)
    }

    // MARK: - Actions

    @objc open func didTapOnOverlay() {
        dismiss(animated: true)
    }
}
