//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamChat
import StreamChatAI

/// An `AIChatTransport` over a Stream Chat channel, which an agent answers in by the Stream AI
/// backend contract.
///
/// It follows the channel's messages and its AI indicator events, sends what the person asks as
/// a message in the channel, and stops the agent with an AI indicator stop event. It follows the
/// channel through the controller's publishers, so the controller's delegate stays free.
///
/// The contract has no way to write a reply again or to edit a message, so a regenerated reply
/// asks its question again, and an edited message is sent as a new one. An agent with an API of
/// its own would take those, and the messages, there instead.
@MainActor
final class DemoAIChatTransport: AIChatTransport {
    private let channel: ChatChannelController
    /// Stream delivers AI indicator events to the client's events controller, not a channel's.
    private let events: EventsController
    private var feed: AIChatFeed<DemoAIChatMessage>?
    private var subscriptions: Set<AnyCancellable> = []
    /// The person's messages on their way to the channel, until they get there or fail.
    private var deliveries: [MessageId: CheckedContinuation<Void, any Error>] = [:]

    init(channel: ChatChannelController) {
        self.channel = channel
        events = channel.client.eventsController()
    }

    func connect(_ feed: AIChatFeed<DemoAIChatMessage>) {
        self.feed = feed
        // Read before following the controller, which starts its local observers and leaves the
        // initialized state.
        let needsSynchronizing = channel.state == .initialized
        // The controller calls back on its callback queue, which an app can move off the main one.
        channel.messagesChangesPublisher.map { _ in () }
            .merge(with: channel.statePublisher.map { _ in () })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.channelChanged() } }
            .store(in: &subscriptions)
        events.allEventsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in MainActor.assumeIsolated { self?.received(event) } }
            .store(in: &subscriptions)
        if needsSynchronizing {
            channel.synchronize()
        }
        channelChanged()
    }

    /// Sends what the person asks as a message, and returns once it is in the channel.
    func send(_ request: AIChatRequest<DemoAIChatMessage>) async throws {
        let attachments = try attachments(of: request)
        try await withCheckedThrowingContinuation { (done: CheckedContinuation<Void, any Error>) in
            channel.createNewMessage(messageId: request.messageID, text: request.text, attachments: attachments) { result in
                done.resume(with: result.map { _ in () })
            }
        }
        // The message is created on the device first, and sent to the channel after.
        if let delivered = Self.delivery(of: request.messageID, in: messages) {
            return try delivered.get()
        }
        try await withCheckedThrowingContinuation { deliveries[request.messageID] = $0 }
    }

    func stop() async throws {
        let stop = AIIndicatorStopEvent(cid: channel.cid)
        try await withCheckedThrowingContinuation { (done: CheckedContinuation<Void, any Error>) in
            channel.eventsController().sendEvent(stop) { error in
                if let error {
                    done.resume(throwing: error)
                } else {
                    done.resume()
                }
            }
        }
    }

    func loadOlderMessages() async throws {
        defer { feed?.update(hasOlderMessages: hasOlderMessages) }
        try await withCheckedThrowingContinuation { (done: CheckedContinuation<Void, any Error>) in
            channel.loadPreviousMessages { error in
                if let error {
                    done.resume(throwing: error)
                } else {
                    done.resume()
                }
            }
        }
    }

    // MARK: - Following the channel

    /// The channel's messages, oldest first.
    private var messages: [ChatMessage] {
        channel.messageOrdering == .topToBottom ? channel.messages.reversed() : channel.messages
    }

    private var hasOlderMessages: Bool {
        channel.state == .remoteDataFetched && !channel.hasLoadedAllPreviousMessages
    }

    private func channelChanged() {
        let messages = messages
        feed?.update(messages: messages.filter(\.isShownInAIConversation).map(DemoAIChatMessage.init))
        feed?.update(hasOlderMessages: hasOlderMessages)
        for (id, delivery) in deliveries {
            guard let delivered = Self.delivery(of: id, in: messages) else { continue }
            deliveries[id] = nil
            delivery.resume(with: delivered)
        }
    }

    private func received(_ event: Event) {
        guard let cid = channel.cid else { return }
        switch event {
        case let update as AIIndicatorUpdateEvent where update.cid == cid:
            feed?.update(activity: AIAgentActivity(state: .init(rawValue: update.state.rawValue), text: update.aiMessage))
        case let clear as AIIndicatorClearEvent where clear.cid == cid:
            feed?.update(activity: nil)
        default:
            break
        }
    }

    /// Whether the message got to the channel or couldn't, or nil while it is on its way.
    private static func delivery(of id: MessageId, in messages: [ChatMessage]) -> Result<Void, any Error>? {
        guard let message = messages.first(where: { $0.id == id }) else { return nil }
        switch message.localState {
        case nil:
            return .success(())
        case .sendingFailed?:
            return .failure(MessageNotSent())
        default:
            return nil
        }
    }

    // MARK: - Attachments

    /// The files the person picked, after those their earlier message carried, which go again:
    /// the edited message's, or those of the question a regenerated reply answered.
    private func attachments(of request: AIChatRequest<DemoAIChatMessage>) throws -> [AnyAttachmentPayload] {
        let picked = try request.attachments.map { url in
            try AnyAttachmentPayload(
                localFileURL: url,
                attachmentType: AIMessageAttachment(url: url).kind == .image ? .image : .file
            )
        }
        let earlier: ChatMessage?
        if request.kind == .edit {
            earlier = request.message?.message
        } else if request.kind == .regenerate {
            earlier = question(answeredBy: request.message)
        } else {
            earlier = nil
        }
        return (earlier.map(Self.uploadedAttachments) ?? []) + picked
    }

    /// The person's message a reply answers: their latest before it, or their latest of all
    /// without a reply.
    private func question(answeredBy reply: DemoAIChatMessage?) -> ChatMessage? {
        let messages = messages.filter(\.isShownInAIConversation).map(DemoAIChatMessage.init)
        let end = reply.flatMap { reply in messages.firstIndex { $0.id == reply.id } } ?? messages.endIndex
        return messages[..<end].last { $0.role == .user }?.message
    }

    private static func uploadedAttachments(of message: ChatMessage) -> [AnyAttachmentPayload] {
        message.imageAttachments.map { image in
            AnyAttachmentPayload(payload: ImageAttachmentPayload(title: image.title, imageRemoteURL: image.imageURL, file: image.file))
        } + message.videoAttachments.map { video in
            AnyAttachmentPayload(payload: VideoAttachmentPayload(title: video.title, videoRemoteURL: video.videoURL, file: video.file, extraData: nil))
        } + message.fileAttachments.map { file in
            AnyAttachmentPayload(payload: FileAttachmentPayload(title: file.title, assetRemoteURL: file.assetURL, file: file.file, extraData: nil))
        }
    }

    private struct MessageNotSent: LocalizedError {
        var errorDescription: String? {
            "Your message couldn't be sent. Try again."
        }
    }
}
