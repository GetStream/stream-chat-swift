//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Abstract controller representing list of messages with message composer.
/// You should never instantiate this class. Instead stick to one of subclasses.
/// When subclassing you must override without calling super all methods of `ChatMessageListVCDataSource`
open class ChatVC<ExtraData: ExtraDataTypes>: ViewController,
    UIConfigProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    MessageComposerViewControllerDelegate {
    // MARK: - Properties

    public var channelController: _ChatChannelController<ExtraData>!
    public var userSuggestionSearchController: _ChatUserSearchController<ExtraData>!

    public private(set) lazy var messageComposerViewController = uiConfig
        .messageComposer
        .messageComposerViewController
        .init()

    public private(set) lazy var messageList = uiConfig
        .messageList
        .messageListVC
        .init()

    private var navbarListener: ChatChannelNavigationBarListener<ExtraData>?
    
    private var messageComposerBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Life Cycle

    override open func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    @objc func keyboardWillChangeFrame(notification: NSNotification) {
        guard
            let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let localFrame = view.convert(frame, from: nil)
        messageComposerBottomConstraint?.constant = -(view.bounds.height - localFrame.minY)

        let collectionDelta = view.bounds.height - view.safeAreaInsets.bottom - localFrame.minY
        let needUpdateContentOffset = !messageList.collectionView.isDecelerating && !messageList.collectionView.isDragging
        let newContentOffset = CGPoint(
            x: 0,
            y: messageList.collectionView.contentOffset.y + collectionDelta
        )
        
        UIView.animate(
            withDuration: duration,
            delay: 0.0,
            options: UIView.AnimationOptions(rawValue: curve),
            animations: { [weak self] in
                self?.view.layoutIfNeeded()
                if needUpdateContentOffset {
                    self?.messageList.collectionView.contentOffset = newContentOffset
                }
            }
        )
    }

    override open func setUpLayout() {
        super.setUpLayout()
        
        messageList.view.translatesAutoresizingMaskIntoConstraints = false
        messageComposerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChildViewController(messageList, targetView: view)
        addChildViewController(messageComposerViewController, targetView: view)

        messageList.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        messageList.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        messageList.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        messageList.view.bottomAnchor.constraint(equalTo: messageComposerViewController.view.topAnchor).isActive = true

        messageComposerViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
            .isActive = true
        messageComposerViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            .isActive = true
        messageComposerBottomConstraint =
            messageComposerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true
    }

    override public func defaultAppearance() {
        super.defaultAppearance()

        view.backgroundColor = uiConfig.colorPalette.generalBackground

        let title = UILabel()
        title.textAlignment = .center
        title.font = .preferredFont(forTextStyle: .headline)

        let subtitle = UILabel()
        subtitle.textAlignment = .center
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = uiConfig.colorPalette.subtitleText

        let titleView = UIStackView(arrangedSubviews: [title, subtitle])
        titleView.axis = .vertical
        navigationItem.titleView = titleView

        navbarListener = makeNavbarListener { data in
            title.text = data.title
            subtitle.text = data.subtitle
        }
    }

    // MARK: - To override

    func makeNavbarListener(
        _ handler: @escaping (ChatChannelNavigationBarListener<ExtraData>.NavbarData) -> Void
    ) -> ChatChannelNavigationBarListener<ExtraData>? {
        nil
    }

    // MARK: - ChatMessageListVCDataSource

    // swiftlint:disable:next unavailable_function
    public func numberOfMessagesInChatMessageListVC(_ vc: ChatMessageListVC<ExtraData>) -> Int {
        fatalError("Abstract class violation")
    }

    // swiftlint:disable:next unavailable_function
    public func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        fatalError("Abstract class violation")
    }

    // swiftlint:disable:next unavailable_function
    public func loadMoreMessagesForChatMessageListVC(_ vc: ChatMessageListVC<ExtraData>) {
        fatalError("Abstract class violation")
    }

    // swiftlint:disable:next unavailable_function
    public func chatMessageListVC(
        _ vc: ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>? {
        fatalError("Abstract class violation")
    }

    // swiftlint:disable:next unavailable_function
    public func chatMessageListVC(
        _ vc: ChatMessageListVC<ExtraData>,
        controllerFor message: _ChatMessage<ExtraData>
    ) -> _ChatMessageController<ExtraData> {
        fatalError("Abstract class violation")
    }

    // MARK: - ChatMessageListVCDelegate

    public func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, didSelectMessageAt index: Int) {
        let selectedMessage = chatMessageListVC(vc, messageAt: index)
        debugPrint(selectedMessage)
    }

    public func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, didTapOnRepliesFor message: _ChatMessage<ExtraData>) {}
    
    public func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, didTapOnInlineReplyFor message: _ChatMessage<ExtraData>) {
        messageComposerViewController.state = .reply(message)
    }
    
    public func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, didTapOnEdit message: _ChatMessage<ExtraData>) {
        messageComposerViewController.state = .edit(message)
    }

    // MARK: - MessageComposerViewControllerDelegate

    public func messageComposerViewControllerDidSendMessage(_ vc: MessageComposerViewController<ExtraData>) {
        messageList.setNeedsScrollToMostRecentMessage()
    }
}
