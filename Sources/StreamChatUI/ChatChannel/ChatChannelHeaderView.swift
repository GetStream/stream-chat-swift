//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays channel information on the message list header
open class ChatChannelHeaderView:
    _View,
    ThemeProvider,
    ChatChannelControllerDelegate {
    /// Controller for observing data changes within the channel.
    open var channelController: ChatChannelController? {
        didSet {
            channelController?.delegate = self
        }
    }

    /// Returns the date formater function used to represent when the user was last seen online
    open var lastSeenDateFormatter: (Date) -> String? { DateUtils.timeAgo }

    /// The user id of the current logged in user.
    open var currentUserId: UserId? {
        channelController?.client.currentUserId
    }

    /// Timer used to update the online status of member in the channel.
    open var timer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }

    /// A View which displays information about current users who are typing.
    open private(set) lazy var typingIndicatorView: TypingIndicatorView = components
        .typingIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints

    /// A Boolean value indicating whether the typing events are enabled.
    open var isTypingEventsEnabled: Bool {
        channelController?.areTypingEventsEnabled == true
    }

    /// The amount of time it updates the online status of the members.
    /// By default it is 60 seconds.
    open var statusUpdateInterval: TimeInterval { 60 }

    private var isUserTyping = false

    /// A view that displays a title label and subtitle in a container stack view.
    open private(set) lazy var titleContainerView: TitleContainerView = components
        .titleContainerView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        makeTimer()
        setupTypingIndicator()
    }

    private func setupTypingIndicator() {
        insertSubview(typingIndicatorView, at: 0)
        typingIndicatorView.isHidden = true
        typingIndicatorView.heightAnchor.pin(equalToConstant: 15).isActive = true
        typingIndicatorView.pin(anchors: [.leading, .trailing], to: self)
        typingIndicatorView.bottomAnchor.pin(equalTo: bottomAnchor).isActive = true
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(titleContainerView)
    }

    override open func updateContent() {
        super.updateContent()

        channelTitleText { [weak self] title in
            guard let self = self else { return }
            self.titleContainerView.content = (title?.trimStringBy(count: 25), self.subtitleText, self.channelController?.channelQuery.type == .announcement ? true : false, self.channelController?.channel?.isMuted ?? false)
            self.titleContainerView.setUpLayout()
        }
    }

    /// Shows typing Indicator.
    /// - Parameter typingUsers: typing users gotten from `channelController`
    open func showTypingIndicator(typingUsers: [ChatUser]) {
        guard isTypingEventsEnabled else { return }

        if let user = typingUsers.first(where: { user in user.name != nil }), let name = user.name {
            typingIndicatorView.content = L10n.MessageList.TypingIndicator.users(name, typingUsers.count - 1)
        } else {
            // If we somehow cannot fetch any user name, we simply show that `Someone is typing`
            typingIndicatorView.content = L10n.MessageList.TypingIndicator.typingUnknown
        }
        isUserTyping = true
        titleContainerView.updateSubtitle(isHide: true)
        typingIndicatorView.isHidden = false
    }

    /// Hides typing Indicator.
    open func hideTypingIndicator() {
        guard isTypingEventsEnabled, typingIndicatorView.isVisible else { return }
        isUserTyping = true
        typingIndicatorView.isHidden = true
        titleContainerView.updateSubtitle(isHide: false)
        updateContent()
    }

    /// The title text used to render the title label. By default it is the channel name.
    open var titleText: String? {
        guard let channel = channelController?.channel else { return nil }
        return components.channelNamer(channel, currentUserId)
    }

    open func opponentWalletAddress(channel: ChatChannel, completion: @escaping ((String?) -> Void)) {
        guard let controller = channelController else {
            completion(nil)
            return
        }
        let memberListController = controller.client.memberListController(query: .init(cid: channel.cid))
        memberListController.synchronize { [weak self] error in
            guard error == nil, let weakSelf = self else { return }
            if channel.isDirectMessageChannel { // 1-1 chat
                let opponent = memberListController.members.filter({ (member: ChatChannelMember) -> Bool in
                    return member.id != memberListController.client.currentUserId
                })
                if let firstMember = opponent.first {
                    let extraData = firstMember.extraData
                    if let walletAddress = extraData["walletAddress"] {
                        let wallet = fetchRawData(raw: walletAddress) as? String ?? ""
                        completion(wallet)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    open func channelTitleText(completion: @escaping ((String?) -> Void)) {
        guard let channel = channelController?.channel else {
            completion(nil)
            return
        }
        if let channelName = components.channelNamer(channel, currentUserId) {
            if channelName.isEmpty {
                opponentWalletAddress(channel: channel, completion: completion)
            } else {
                completion(channelName)
            }
        } else {
            completion(nil)
        }
    }


    /// The subtitle text used in the subtitle label. By default it shows member online status.
    open var subtitleText: String? {
        guard let channel = channelController?.channel else { return nil }
        guard let currentUserId = self.currentUserId else { return nil }

        if channel.isDirectMessageChannel {
            guard let member = channel
                .lastActiveMembers
                .first(where: { $0.id != currentUserId })
            else {
                return nil
            }

            if member.isOnline {
                return L10n.Message.Title.online
            } else if let lastActiveAt = member.lastActiveAt, let timeAgo = lastSeenDateFormatter(lastActiveAt) {
                return timeAgo
            } else {
                return L10n.Message.Title.offline
            }
        }
        let activeMembers = channel.lastActiveMembers.filter( {$0.isOnline}).count
        return L10n.Message.Title.group(channel.memberCount, activeMembers)
    }

    /// Create the timer to repeatedly update the online status of the members.
    open func makeTimer() {
        // Only create the timer if is not created yet and if the interval is not zero.
        guard timer == nil, statusUpdateInterval > 0 else {
            return
        }

        timer = Timer.scheduledTimer(
            withTimeInterval: statusUpdateInterval,
            repeats: true
        ) { [weak self] _ in
            guard let `self` = self, !self.isUserTyping else { return }
            self.updateContentIfNeeded()
        }
    }

    // MARK: - ChatChannelControllerDelegate Implementation

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        switch channel {
        case .update, .create:
            guard !self.isUserTyping else { return }
            updateContentIfNeeded()
        default:
            break
        }
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        guard channelController.areTypingEventsEnabled else { return }

        let typingUsersWithoutCurrentUser = typingUsers
            .sorted { $0.id < $1.id }
            .filter { $0.id != ChatClient.shared.currentUserId }

        if typingUsersWithoutCurrentUser.isEmpty {
            self.hideTypingIndicator()
        } else {
            self.showTypingIndicator(typingUsers: typingUsersWithoutCurrentUser)
        }
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didReceiveMemberEvent: MemberEvent
    ) {
        // By default the header view is not interested in member events
        // but this can be overridden by subclassing this component.
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        // By default the header view is not interested in message events
        // but this can be overridden by subclassing this component.
    }

    deinit {
        timer?.invalidate()
    }
}

extension String {
    func trimStringBy(count: Int) -> String {
        let newString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.count > count {
            let prefix = String(newString.prefix(count))
            return "\(prefix)..."
        }
        return self
    }
}
