//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelVC:
    _ViewController,
    ThemeProvider,
    ChatMessageListVCDelegate,
    ChatMessageActionsVCDelegate {
    /// User search controller passed directly to the composer
    open var userSuggestionSearchController: ChatUserSearchController!

    /// Controller for observing data changes within the channel
    open var channelController: ChatChannelController!

    public var client: ChatClient {
        channelController.client
    }

    /// Observer responsible for setting the correct offset when keyboard frame is changed
    open lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        composerBottomConstraint: messageComposerBottomConstraint,
        viewController: self
    )

    open lazy var messageListVC: ChatMessageListVC = components
        .messageListVC
        .init()

    /// A router object that handles navigation to other view controllers.
    open lazy var router = components
        .messageListRouter
        .init(rootViewController: self)

    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC = components
        .messageComposerVC
        .init()

    private var messageComposerBottomConstraint: NSLayoutConstraint?

    /// Header View
    open private(set) lazy var headerView: ChatChannelHeaderView = components
        .channelHeaderView.init()
        .withoutAutoresizingMaskConstraints

    /// View for displaying the channel image in the navigation bar.
    open private(set) lazy var channelAvatarView = components
        .channelAvatarView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        messageListVC.channelController = channelController
        messageListVC.router = router
        messageListVC.delegate = self

        messageComposerVC.channelController = channelController
        messageComposerVC.userSearchController = userSuggestionSearchController

        channelController.synchronize { [weak self] _ in
            self?.messageComposerVC.updateContent()
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.backgroundColor = appearance.colorPalette.background

        messageListVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageListVC, targetView: view)
        messageListVC.view.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)

        messageComposerVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageComposerVC, targetView: view)
        messageComposerVC.view.pin(anchors: [.leading, .trailing], to: view)
        messageComposerVC.view.topAnchor.pin(equalTo: messageListVC.view.bottomAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            channelAvatarView.widthAnchor.pin(equalTo: channelAvatarView.heightAnchor),
            channelAvatarView.heightAnchor.pin(equalToConstant: 32)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatarView)
        channelAvatarView.content = (channelController.channel, client.currentUserId)

        if let cid = channelController.cid {
            headerView.channelController = client.channelController(for: cid)
        }
        navigationItem.titleView = headerView
        navigationItem.largeTitleDisplayMode = .never
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        keyboardObserver.register()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        resignFirstResponder()

        keyboardObserver.unregister()
    }

    // MARK: - _ChatMessageListVCDelegate

    public func chatMessageList(
        _ vc: ChatMessageListVC,
        didSelectMessage message: ChatMessage,
        messageContentView: ChatMessageContentView
    ) {
        let messageController = channelController.client.messageController(
            cid: channelController.cid!,
            messageId: message.id
        )

        let actionsController = components.messageActionsVC.init()
        actionsController.messageController = messageController
        actionsController.channelConfig = channelController.channel?.config
        actionsController.delegate = self

        let reactionsController: ChatMessageReactionsVC? = {
            guard message.localState == nil else { return nil }
            guard channelController.channel?.config.reactionsEnabled == true else {
                return nil
            }

            let controller = components.messageReactionsVC.init()
            controller.messageController = messageController
            return controller
        }()

        router.showMessageActionsPopUp(
            messageContentView: messageContentView,
            messageActionsController: actionsController,
            messageReactionsController: reactionsController
        )
    }

    // MARK: - _ChatMessageActionsVCDelegate

    open func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
    ) {
        switch actionItem {
        case is EditActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.editMessage(message)
            }
        case is InlineReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.quoteMessage(message)
            }
        case is ThreadReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageListVC.showThread(messageId: message.id)
            }
        default:
            return
        }
    }

    open func chatMessageActionsVCDidFinish(_ vc: ChatMessageActionsVC) {
        dismiss(animated: true)
    }
}
