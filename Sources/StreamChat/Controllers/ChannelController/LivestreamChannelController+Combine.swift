//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension LivestreamChannelController {
    /// A publisher emitting a new value every time the channel changes.
    public var channelChangePublisher: AnyPublisher<ChatChannel?, Never> {
        basePublishers.channelChange.keepAlive(self)
    }

    /// A publisher emitting a new value every time the list of messages changes.
    public var messagesChangesPublisher: AnyPublisher<[ChatMessage], Never> {
        basePublishers.messagesChanges.keepAlive(self)
    }

    /// A publisher emitting a new value every time the pause state changes.
    public var isPausedPublisher: AnyPublisher<Bool, Never> {
        basePublishers.isPaused.keepAlive(self)
    }

    /// A publisher emitting a new value every time the skipped messages amount changes.
    public var skippedMessagesAmountPublisher: AnyPublisher<Int, Never> {
        basePublishers.skippedMessagesAmount.keepAlive(self)
    }

    /// A publisher emitting a new value every time the set of currently typing users changes.
    ///
    /// The publisher's initial value is captured from `controller.channel?.currentlyTypingUsers`
    /// at the time the controller's Combine bridge is first accessed. If a subscriber attaches
    /// before `synchronize()` resolves the channel, the initial value will be an empty set;
    /// subsequent updates are still delivered as typing events arrive.
    public var typingUsersPublisher: AnyPublisher<Set<ChatUser>, Never> {
        basePublishers.typingUsers.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: LivestreamChannelController

        /// A backing subject for `channelChangePublisher`.
        let channelChange: CurrentValueSubject<ChatChannel?, Never>

        /// A backing subject for `messagesChangesPublisher`.
        let messagesChanges: CurrentValueSubject<[ChatMessage], Never>

        /// A backing subject for `isPausedPublisher`.
        let isPaused: CurrentValueSubject<Bool, Never>

        // A backing subject for `skippedMessagesAmountPublisher`.
        let skippedMessagesAmount: CurrentValueSubject<Int, Never>

        /// A backing subject for `typingUsersPublisher`.
        let typingUsers: CurrentValueSubject<Set<ChatUser>, Never>

        init(controller: LivestreamChannelController) {
            self.controller = controller
            channelChange = .init(controller.channel)
            messagesChanges = .init(controller.messages)
            skippedMessagesAmount = .init(controller.skippedMessagesAmount)
            isPaused = .init(controller.isPaused)
            typingUsers = .init(controller.channel?.currentlyTypingUsers ?? [])
            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension LivestreamChannelController.BasePublishers: LivestreamChannelControllerDelegate {
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateChannel channel: ChatChannel
    ) {
        channelChange.send(channel)
    }

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateMessages messages: [ChatMessage]
    ) {
        messagesChanges.send(messages)
    }

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangePauseState isPaused: Bool
    ) {
        self.isPaused.send(isPaused)
    }

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangeSkippedMessagesAmount skippedMessagesAmount: Int
    ) {
        self.skippedMessagesAmount.send(skippedMessagesAmount)
    }

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        self.typingUsers.send(typingUsers)
    }
}
