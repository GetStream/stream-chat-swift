//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import RxCocoa
import RxSwift
import StreamChatClient
import UIKit

/// A channel presenter.
public final class ChannelPresenter: Presenter {
    typealias EphemeralType = (message: Message?, updated: Bool)
    
    /// A callback type for the adding an extra data for a new message.
    public typealias MessageExtraDataCallback = (_ id: String, _ text: String, [Attachment], _ parentId: String?) -> Codable?
    /// A callback type for the adding an extra data for a new reaction.
    public typealias ReactionExtraDataCallback = (String, _ score: Int, _ messageId: String) -> Codable?
    /// A callback type for the adding an extra data for a file attachment.
    public typealias FileAttachmentExtraDataCallback = (URL, Channel) -> Codable?
    /// A callback type for the adding an extra data for an image attachment.
    public typealias ImageAttachmentExtraDataCallback = (URL?, UIImage?, _ isVideo: Bool, Channel) -> Codable?
    /// A callback type for preparing the message before sending.
    public typealias MessagePreparationCallback = (Message) -> Message?
    
    /// A callback for the adding an extra data for a new message.
    public var messageExtraDataCallback: MessageExtraDataCallback?
    /// A callback for the adding an extra data for a new message.
    public var reactionExtraDataCallback: ReactionExtraDataCallback?
    /// A callback for the adding an extra data for a file attachment.
    public var fileAttachmentExtraDataCallback: FileAttachmentExtraDataCallback?
    /// A callback for the adding an extra data for a file attachment.
    public var imageAttachmentExtraDataCallback: ImageAttachmentExtraDataCallback?
    /// A callback for preparing the message before sending.
    public var messagePreparationCallback: MessagePreparationCallback?
    
    let channelType: ChannelType
    let channelId: String
    let channelPublishSubject = PublishSubject<Channel>()
    
    private(set) lazy var channelAtomic = Atomic<Channel>(.unused, callbackQueue: .main) { [weak self] channel, oldChannel in
        if oldChannel.cid != Channel.unused.cid {
            channel.namingStrategy = oldChannel.namingStrategy
            channel.banEnabling = oldChannel.banEnabling
            if oldChannel.cid == channel.cid, channel.members.isEmpty {
                // Sometimes, the event does not include the member info
                // When that's the case, we can keep the old member info
                channel.members = oldChannel.members
                channel.membership = oldChannel.membership
            }
        }
        self?.channelPublishSubject.onNext(channel)
    }
    
    /// A channel (see `Channel`).
    public var channel: Channel { channelAtomic.get() }
    /// A parent message for replies.
    public var parentMessage: Message?
    /// Checks if the presenter is in a thread.
    public var isThread: Bool { parentMessage != nil }
    /// Query options.
    public let queryOptions: QueryOptions
    /// An edited message.
    public var editMessage: Message?
    /// Show statuses separators, e.g. Today
    public var showStatuses = true
    let lastMessageAtomic = Atomic<Message?>()
    /// The last parsed message from WebSocket events.
    public var lastMessage: Message? { lastMessageAtomic.get() }
    var lastAddedOwnMessage: Message?
    var lastParsedEvent: StreamChatClient.Event?
    var lastWebSocketEventViewChanges: ViewChanges?
    
    /// A list of typing users (see `TypingUser`).
    public internal(set) var typingUsers: [TypingUser] = []
    
    /// Checks if user typing events enabled for the channel.
    public var isTypingEventsEnabled: Bool { channel.config.typingEventsEnabled && !isThread }
    
    var messageIdByMessageReadUser: [User: String] = [:]
    /// Check if the channel has unread messages.
    public var isUnread: Bool {
        if let lastMessage = lastMessage, lastMessage.isOwn { return false }
        else { return channel.isUnread }
    }
    
    let ephemeralSubject = BehaviorSubject<EphemeralType>(value: (nil, false))
    /// Check if the channel has ephemeral message, e.g. Giphy preview.
    public var hasEphemeralMessage: Bool { ephemeralMessage != nil }
    /// An ephemeral message, e.g. Giphy preview.
    public var ephemeralMessage: Message? { (try? ephemeralSubject.value())?.message }
    
    /// Check if the user can reply (create a thread) to a message.
    public var canReply: Bool { !isThread && channel.config.repliesEnabled }
    
    /// A filter to discard channel events.
    public var eventsFilter: StreamChatClient.Event.Filter?
    
    /// Uploader for images and files.
    public lazy var uploadManager = UploadManager()
    
    /// It will trigger `channel.stopWatching()` if needed when the presenter was deallocated.
    /// It's no needed if you will disconnect when the presenter will be deallocated.
    public var stopWatchingIfNeeded = false
    
    /// Init a presenter with a given channel.
    ///
    /// - Parameters:
    ///     - channel: a channel
    ///     - parentMessage: a parent message for replies
    ///     - showStatuses: shows statuses separators, e.g. Today
    public init(channel: Channel, parentMessage: Message? = nil, queryOptions: QueryOptions = .all) {
        channelType = channel.type
        channelId = channel.id
        self.parentMessage = parentMessage
        self.queryOptions = queryOptions
        super.init(pageSize: [.messagesPageSize])
        channelAtomic.set(channel)
    }
    
    /// Init a presenter with a given channel query.
    ///
    /// - Parameters:
    ///     - query: a channel query result with messages
    ///     - showStatuses: shows statuses separators, e.g. Today
    public init(response: ChannelResponse, queryOptions: QueryOptions, showStatuses: Bool = true) {
        channelType = response.channel.type
        channelId = response.channel.id
        parentMessage = nil
        self.queryOptions = queryOptions
        self.showStatuses = showStatuses
        super.init(pageSize: [.messagesPageSize])
        parse(response: response)
    }
    
    deinit {
        if stopWatchingIfNeeded, channel.didLoad {
            let channel = self.channel
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1 + .milliseconds(Int.random(in: 0...3000))) {
                if Client.shared.isConnected {
                    channel.stopWatching()
                }
            }
        }
    }
}

// MARK: - Changes

public extension ChannelPresenter {
    /// Subscribes for `ViewChanges`.
    /// - Parameter onNext: a co    mpletion block with `ViewChanges`.
    /// - Returns: a subscription.
    func changes(_ onNext: @escaping Client.Completion<ViewChanges>) -> AutoCancellable {
        rx.changes.asObservable().bind(to: onNext)
    }
    
    /// An observable channel (see `Channel`).
    func channelDidUpdate(_ onNext: @escaping Client.Completion<Channel>) -> AutoCancellable {
        rx.channelDidUpdate.asObservable().bind(to: onNext)
    }
}

// MARK: - Send Message

extension ChannelPresenter {
    /// Create a message by sending a text.
    /// - Parameters:
    ///     - text: a message text
    ///     - showReplyInChannel: show a reply in the channel.
    ///     - parseMentionedUsers: whether to automatically parse mentions into the `message.mentionedUsers` property. Defaults to `true`.
    ///     - completion: a completion block with `MessageResponse`.
    public func send(
        text: String,
        showReplyInChannel: Bool = false,
        parseMentionedUsers: Bool = true,
        _ completion: @escaping Client.Completion<MessageResponse>
    ) {
        rx.send(text: text, showReplyInChannel: showReplyInChannel, parseMentionedUsers: parseMentionedUsers)
            .bindOnce(to: completion)
    }
    
    func createMessage(with text: String, showReplyInChannel: Bool) -> Message {
        let messageId = editMessage?.id ?? ""
        
        var attachments = uploadManager.files.compactMap(\.attachment) + uploadManager.images.compactMap(\.attachment)
        
        var extraData: Codable?
        
        if attachments.isEmpty, let editMessage = editMessage, !editMessage.attachments.isEmpty {
            attachments = editMessage.attachments
        }
        
        if let messageExtraDataCallback = messageExtraDataCallback {
            extraData = messageExtraDataCallback(messageId, text, attachments, parentMessage?.id)
        }
        
        editMessage = nil
        var mentionedUsers = [User]()
        
        // Add mentiond users
        if !text.isEmpty, text.contains("@"), !channel.members.isEmpty {
            let text = text.lowercased()
            
            channel.members.forEach { member in
                if text.contains("@\(member.user.name.lowercased())") {
                    mentionedUsers.append(member.user)
                }
            }
        }
        
        let message = Message(
            id: messageId,
            parentId: parentMessage?.id,
            text: text,
            attachments: attachments,
            mentionedUsers: mentionedUsers,
            extraData: extraData,
            showReplyInChannel: showReplyInChannel && isThread
        )
        
        return messagePreparationCallback?(message) ?? message
    }
}

// MARK: - Unused Channel for Atomic

extension Channel {
    public static let unused = Channel(
        type: "",
        id: "",
        members: [],
        invitedMembers: [],
        extraData: nil,
        created: .init(),
        deleted: nil,
        createdBy: nil,
        lastMessageDate: nil,
        frozen: true,
        config: .init()
    )
}
