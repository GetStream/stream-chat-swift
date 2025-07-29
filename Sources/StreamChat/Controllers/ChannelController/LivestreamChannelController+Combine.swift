//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

        init(controller: LivestreamChannelController) {
            self.controller = controller
            channelChange = .init(controller.channel)
            messagesChanges = .init(controller.messages)

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
}
