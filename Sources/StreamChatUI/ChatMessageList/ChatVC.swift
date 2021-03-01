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
            let oldFrame = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let localFrame = view.convert(frame, from: nil)
        let localOldFrame = view.convert(oldFrame, from: nil)

        // message composer follows keyboard
        messageComposerBottomConstraint?.constant = -(view.bounds.height - localFrame.minY)

        // calculate new contentOffset for message list, so bottom message still visible when keyboard appears
        var keyboardTop = localFrame.minY
        if keyboardTop == view.bounds.height {
            keyboardTop -= view.safeAreaInsets.bottom
        }

        var oldKeyboardTop = localOldFrame.minY
        if oldKeyboardTop == view.bounds.height {
            oldKeyboardTop -= view.safeAreaInsets.bottom
        }

        let keyboardDelta = oldKeyboardTop - keyboardTop
        let newContentOffset = CGPoint(
            x: 0,
            y: messageList.collectionView.contentOffset.y + keyboardDelta
        )

        // changing contentOffset will cancel any scrolling in collectionView, bad UX
        let needUpdateContentOffset = !messageList.collectionView.isDecelerating && !messageList.collectionView.isDragging
        
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
        
        // Not a nice solution but as composer changes its intrinsicContentSize several times after getting on screen
        // it creates ugly jump of message list, this way we can workaround it until this behavior is fixed
        messageComposerViewController.view.layoutIfNeeded()
        
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
    }

    override public func defaultAppearance() {
        super.defaultAppearance()

        view.backgroundColor = uiConfig.colorPalette.background
        let title = UILabel()
        title.textAlignment = .center
        title.font = uiConfig.font.headlineBold

        let subtitle = UILabel()
        subtitle.textAlignment = .center
        subtitle.font = uiConfig.font.caption1
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
    public func numberOfMessagesInChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) -> Int {
        fatalError("Abstract class violation")
    }

    // swiftlint:disable:next unavailable_function
    public func chatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>, messageAt index: Int) -> _ChatMessage<ExtraData> {
        fatalError("Abstract class violation")
    }

    // swiftlint:disable:next unavailable_function
    public func loadMoreMessagesForChatMessageListVC(_ vc: _ChatMessageListVC<ExtraData>) {
        fatalError("Abstract class violation")
    }

    // swiftlint:disable:next unavailable_function
    public func chatMessageListVC(
        _ vc: _ChatMessageListVC<ExtraData>,
        replyMessageFor message: _ChatMessage<ExtraData>,
        at index: Int
    ) -> _ChatMessage<ExtraData>? {
        fatalError("Abstract class violation")
    }

    // swiftlint:disable:next unavailable_function
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
