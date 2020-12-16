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
    ChatMessageListVCDelegate {
    // MARK: - Properties

    public var channelController: _ChatChannelController<ExtraData>!

    // TODO: composer input must be able to distinguish between channel message send and thread message send
    public private(set) lazy var messageInputAccessoryViewController: MessageComposerInputAccessoryViewController<ExtraData> = {
        let inputAccessoryVC = MessageComposerInputAccessoryViewController<ExtraData>()

        // `inputAccessoryViewController` is part of `_UIKeyboardWindowScene` so we need to manually pass
        // tintColor down that `inputAccessoryViewController` view hierarchy.
        inputAccessoryVC.view.tintColor = view.tintColor

        return inputAccessoryVC
    }()

    public private(set) lazy var messageList = uiConfig
        .messageList
        .messageListVC
        .init()

    private var navbarListener: ChatChannelNavigationBarListener<ExtraData>?

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

        messageInputAccessoryViewController.controller = channelController
        messageList.delegate = .wrap(self)
        messageList.dataSource = .wrap(self)
    }

    override open func setUpLayout() {
        super.setUpLayout()
        messageList.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageList, targetView: view)
        messageList.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        messageList.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        messageList.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        messageList.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        messageList.collectionView.contentInset.bottom = 100
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

    // MARK: - ChatChannelMessageComposerView

    override open var canBecomeFirstResponder: Bool { true }

    override open var inputAccessoryViewController: UIInputViewController? {
        messageInputAccessoryViewController
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
        messageInputAccessoryViewController.state = .reply(message)
    }
    
    public func chatMessageListVC(_ vc: ChatMessageListVC<ExtraData>, didTapOnEdit message: _ChatMessage<ExtraData>) {
        messageInputAccessoryViewController.state = .edit(message)
    }
}
