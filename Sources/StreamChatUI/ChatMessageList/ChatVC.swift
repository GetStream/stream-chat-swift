//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Abstract controller representing list of messages with message composer.
/// You should never instantiate this class. Instead stick to one of subclasses.
/// When subclassing you must override without calling super all methods of `ChatMessageListVCDataSource`
open class _ChatVC<ExtraData: ExtraDataTypes>: _ViewController,
    UIConfigProvider,
    _ChatMessageListVCDataSource,
    _ChatMessageListVCDelegate,
    _ChatMessageComposerViewControllerDelegate {
    // MARK: - Properties

    public var channelController: _ChatChannelController<ExtraData>!
    public lazy var userSuggestionSearchController: _ChatUserSearchController<ExtraData> = {
        channelController.client.userSearchController()
    }()

    public private(set) lazy var messageComposerViewController = uiConfig
        .messageComposer
        .messageComposerViewController
        .init()

    public private(set) lazy var messageList = uiConfig
        .messageList
        .messageListVC
        .init()

    public private(set) lazy var typingIndicatorView: _TypingIndicatorView<ExtraData> = uiConfig
        .typingIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints

    private var navbarListener: ChatChannelNavigationBarListener<ExtraData>?
    
    private var messageComposerBottomConstraint: NSLayoutConstraint?
    private lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        scrollView: messageList.collectionView,
        composerBottomConstraint: messageComposerBottomConstraint
    )
    
    // MARK: - Life Cycle

    override open func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        keyboardObserver.register()
        
        // This is just a temporary place to do this. When it will be possible to open a channel on any
        // arbitrary message, we should make the channel read only when it scrolls to the very last message.
        if let channel = channelController?.channel, channel.config.readEventsEnabled, channel.unreadCount != .noUnread {
            channelController?.markRead {
                if let error = $0 {
                    log.error("Failed to mark channel \(channel.cid) as read. Error: \(error)")
                } else {
                    log.info("Channel \(channel.cid) mark read.")
                }
            }
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resignFirstResponder()
        
        keyboardObserver.unregister()
    }

    override open func setUp() {
        super.setUp()

        messageComposerViewController.delegate = .wrap(self)
        messageComposerViewController.controller = channelController
        messageComposerViewController.userSuggestionSearchController = userSuggestionSearchController

        messageList.delegate = .wrap(self)
        messageList.dataSource = .wrap(self)

        userSuggestionSearchController.search(term: nil) // Initially, load all users

        typingIndicatorView.isHidden = true
    }

    override open func setUpLayout() {
        super.setUpLayout()
        
        messageList.view.translatesAutoresizingMaskIntoConstraints = false
        messageComposerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChildViewController(messageList, targetView: view)
        addChildViewController(messageComposerViewController, targetView: view)

        messageList.view.leadingAnchor.pin(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        messageList.view.trailingAnchor.pin(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        messageList.view.topAnchor.pin(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        messageList.view.bottomAnchor.pin(equalTo: messageComposerViewController.view.topAnchor).isActive = true

        messageComposerViewController.view.leadingAnchor.pin(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
            .isActive = true
        messageComposerViewController.view.trailingAnchor.pin(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            .isActive = true
        messageComposerBottomConstraint =
            messageComposerViewController.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true

        if channelController.channel?.config.typingEventsEnabled ?? false {
            view.addSubview(typingIndicatorView)
            typingIndicatorView.heightAnchor.pin(equalToConstant: 22).isActive = true
            typingIndicatorView.pin(anchors: [.leading, .trailing], to: view)
            typingIndicatorView.bottomAnchor.pin(equalTo: messageComposerViewController.view.topAnchor).isActive = true
            messageList.collectionView.contentInset.bottom = 22
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        view.backgroundColor = uiConfig.colorPalette.background
        
        let titleView = ChatMessageListTitleView<ExtraData>()

        navigationItem.titleView = titleView

        navbarListener = makeNavbarListener { data in
            titleView.title = data.title
            titleView.subtitle = data.subtitle
        }
    }

    // MARK: - To override

    func makeNavbarListener(
        _ handler: @escaping (ChatChannelNavigationBarListener<ExtraData>.NavbarData) -> Void
    ) -> ChatChannelNavigationBarListener<ExtraData>? {
        nil
    }

    // MARK: - ChatMessageListVCDataSource

    public func numberOfMessagesInChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) -> Int {
        fatalError("Abstract class violation")
    }

    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        fatalError("Abstract class violation")
    }

    public func loadMoreMessagesForChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) {
        fatalError("Abstract class violation")
    }

    public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>? {
        fatalError("Abstract class violation")
    }

    public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        controllerFor message: _ChatMessage<ExtraData>
    ) -> _ChatMessageController<ExtraData> {
        fatalError("Abstract class violation")
    }

    // MARK: - ChatMessageListVCDelegate

    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didSelectMessageAt index: Int) {
        let selectedMessage = chatMessageListVC(vc, messageAt: index)
        debugPrint(selectedMessage)
    }

    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didTapOnRepliesFor message: _ChatMessage<ExtraData>) {}
    
    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didTapOnInlineReplyFor message: _ChatMessage<ExtraData>) {
        messageComposerViewController.state = .quote(message)
    }
    
    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didTapOnEdit message: _ChatMessage<ExtraData>) {
        messageComposerViewController.state = .edit(message)
    }

    // MARK: - MessageComposerViewControllerDelegate

    public func messageComposerViewControllerDidSendMessage(_ vc: _ChatMessageComposerVC<ExtraData>) {
        messageList.setNeedsScrollToMostRecentMessage()
    }
}
