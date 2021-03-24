//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatThreadVC = _ChatThreadVC<NoExtraData>

public class ChatMessageListTitleView<ExtraData: ExtraDataTypes>: UIView, UIConfigProvider {
    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    public var subtitle: String? {
        get { subtitleLabel.text }
        set { subtitleLabel.text = newValue }
    }
    
    private weak var titleLabel: UILabel!
    private weak var subtitleLabel: UILabel!
    
    public init() {
        super.init(frame: .zero)
        
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = uiConfig.font.headlineBold
        self.titleLabel = titleLabel

        let subtitleLabel = UILabel()
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = uiConfig.font.caption1
        subtitleLabel.textColor = uiConfig.colorPalette.subtitleText
        self.subtitleLabel = subtitleLabel

        let titleView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleView.axis = .vertical
        addSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.pin(to: self)
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class _ChatThreadVC<ExtraData: ExtraDataTypes>: _ViewController, UIConfigProvider, _ChatMessageListVCDataSource, _ChatMessageListVCDelegate, _ChatMessageComposerViewControllerDelegate {
    public var controller: _ChatMessageController<ExtraData>!
    public var channelController: _ChatChannelController<ExtraData>!
    public lazy var userSuggestionSearchController: _ChatUserSearchController<ExtraData> = channelController.client.userSearchController()

    public private(set) lazy var messageComposerViewController = uiConfig
        .messageComposer
        .messageComposerViewController
        .init()

    public private(set) lazy var messageList = uiConfig
        .messageList
        .messageListVC
        .init()
    
    public private(set) lazy var titleView = ChatMessageListTitleView<ExtraData>()
    
    private lazy var keyboardObserver = KeyboardFrameObserver(
        containerView: view,
        scrollView: messageList.collectionView,
        composerBottomConstraint: messageComposerBottomConstraint
    )
    
    private var messageComposerBottomConstraint: NSLayoutConstraint?

    // MARK: - Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        keyboardObserver.register()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        messageList.scrollToMostRecentMessageIfNeeded()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        resignFirstResponder()
    }

    override open func setUp() {
        super.setUp()
        
        messageComposerViewController.delegate = .wrap(self)
        messageComposerViewController.controller = channelController
        messageComposerViewController.userSuggestionSearchController = userSuggestionSearchController

        messageList.delegate = .wrap(self)
        messageList.dataSource = .wrap(self)

        userSuggestionSearchController.search(term: nil) // Initially, load all users

        controller.setDelegate(self)
        controller.synchronize()

        messageComposerViewController.threadParentMessage = controller.message
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        messageList.view.translatesAutoresizingMaskIntoConstraints = false
        messageComposerViewController.view.translatesAutoresizingMaskIntoConstraints = false

        addChildViewController(messageList, targetView: view)
        addChildViewController(messageComposerViewController, targetView: view)
        
        messageList.view.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)
        messageList.view.bottomAnchor.pin(equalTo: messageComposerViewController.view.topAnchor).isActive = true

        messageComposerViewController.view.pin(anchors: [.leading, .trailing], to: view.safeAreaLayoutGuide)
        messageComposerBottomConstraint = messageComposerViewController.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true
    }
    
    override public func defaultAppearance() {
        super.defaultAppearance()

        view.backgroundColor = uiConfig.colorPalette.background
        
        titleView.title = "Thread Reply"
        let channelName = channelController.channel?.name ?? "love"
        titleView.subtitle = "with \(channelName)"
        
        navigationItem.titleView = titleView
    }
    
    // MARK: - ChatMessageListVCDelegate

    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didSelectMessageAt index: Int) {
        let selectedMessage = chatMessageListVC(vc, messageAt: index)
        debugPrint(selectedMessage)
    }

    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, didTapOnRepliesFor message: _ChatMessage<ExtraData>) { }
    
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

    // MARK: - ChatMessageListVCDataSource

    public func numberOfMessagesInChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) -> Int {
        controller.replies.count + 1
    }

    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        if index == controller.replies.count {
            return controller.message!
        }
        return controller.replies[index]
    }

    public func loadMoreMessagesForChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) {
        controller.loadPreviousReplies()
    }

    public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>? {
        nil
    }

    public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        controllerFor message: _ChatMessage<ExtraData>
    ) -> _ChatMessageController<ExtraData> {
        controller.client.messageController(
            cid: controller.cid,
            messageId: message.id
        )
    }
}

// MARK: - ChatChannelControllerDelegate

extension _ChatThreadVC: _ChatMessageControllerDelegate {
    public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        messageList.updateMessages(with: changes)
    }
}
