//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/scheduled-messages/

import Combine
import Foundation
import StreamChat

// A file-scope value, so the escaping Combine closure can use it without `self.`
private let parentMessageId: MessageId = "parent-message-id"

@MainActor
final class Snippets_04_12_ScheduledMessages {
    var cancellables = Set<AnyCancellable>()
    var channelController: ChatChannelController!
    var channelId: ChannelId!
    var chat: Chat!
    var chatClient: ChatClient!
    var currentUserId: UserId!
    var messageController: ChatMessageController!
    var scheduledMessageId: String!

    func schedulingAMessage() {
        let cid = ChannelId(type: .messaging, id: "general")
        let scheduledAt = Date().addingTimeInterval(24 * 60 * 60) // In 24 hours

        // Saves the message on the device, and the SDK sends it to the server in the
        // background once its attachments are uploaded and the device is online. Until
        // then its status is .preparingToSchedule. The message is not in the channel
        // until it is sent.
        let channelController = chatClient.channelController(for: cid)
        channelController.delegate = self
        channelController.scheduleMessage(
            text: "Happy birthday!",
            scheduledAt: scheduledAt,
            extraData: ["priority": .string("high")]
        ) { result in
            // An error means the message was refused on the device and not saved: a
            // slash command, a deleted quoted message, a time later than the latest
            // send time, or a message over the channel or user limit.
            if case let .failure(error) = result {
                print("Couldn't schedule the message: \(error)")
            }
        }

        // A thread reply, with the message controller of the parent message
        let messageController = chatClient.messageController(cid: cid, messageId: parentMessageId)
        messageController.scheduleReply(text: "See you there!", scheduledAt: scheduledAt)
    }

    func schedulingAMessageAsync() async throws {
        let cid = ChannelId(type: .messaging, id: "general")
        let scheduledAt = Date().addingTimeInterval(24 * 60 * 60) // In 24 hours

        // Returns once the message is saved on the device, and the SDK sends it to the
        // server in the background once its attachments are uploaded and the device is
        // online. Until then its status is .preparingToSchedule. The message is not in
        // the channel until it is sent.
        // It throws when the message is refused on the device and not saved: a slash
        // command, a deleted quoted message, a time later than the latest send time, or
        // a message over the channel or user limit.
        let chat = chatClient.makeChat(for: cid)
        let scheduledMessage = try await chat.scheduleMessage(
            with: "Happy birthday!",
            scheduledAt: scheduledAt,
            extraData: ["priority": .string("high")]
        )

        // A thread reply
        try await chat.scheduleReply(to: parentMessageId, text: "See you there!", scheduledAt: scheduledAt)

        // The server's answer updates chat.state.channel?.scheduledMessages, which
        // holds the user's scheduled messages in the channel. It is updated whenever
        // one of them changes, on the device or from the server.
        chat.state.$channel
            .sink { channel in
                for scheduledMessage in channel?.scheduledMessages ?? [] {
                    switch scheduledMessage.failure {
                    case let .serverRejectedScheduling(rejection):
                        // The server refused the change, for example because the
                        // channel limit was reached. The message describes it.
                        print("Couldn't schedule \(scheduledMessage.id): \(rejection.message)")
                    case let .serverFailedPublishing(failure):
                        // The server couldn't send it at its time, for example because
                        // the user was banned. It can only be deleted.
                        print("Couldn't send \(scheduledMessage.id): \(failure.reason?.rawValue ?? "unknown")")
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
        suppressUnusedWarning(scheduledMessage)
    }

    func updatingAScheduledMessage() {
        let newScheduledAt = Date().addingTimeInterval(23 * 60 * 60) // In 23 hours

        // Like scheduling, saves the change on the device and sends it to the server in
        // the background. The server's answer updates the message in the scheduled
        // message list.
        channelController.updateScheduledMessage(
            id: scheduledMessageId,
            text: "Happy birthday, John!",
            scheduledAt: newScheduledAt
        ) { result in
            // An error means the change was refused on the device and not saved: a
            // slash command, a deleted quoted message, or a time later than the latest
            // send time.
            if case let .failure(error) = result {
                print("Couldn't update the scheduled message: \(error)")
            }
        }

        // Only the send time
        channelController.rescheduleMessage(id: scheduledMessageId, scheduledAt: newScheduledAt)

        // A thread reply, with the message controller of the parent message
        messageController.updateScheduledReply(id: scheduledMessageId, text: "See you at 8!")
    }

    func updatingAScheduledMessageAsync() async throws {
        let newScheduledAt = Date().addingTimeInterval(23 * 60 * 60) // In 23 hours

        // Like scheduling, returns once the change is saved on the device and sends it
        // to the server in the background. The server's answer updates the message in
        // the scheduled message list.
        // It throws when the change is refused on the device and not saved: a slash
        // command, a deleted quoted message, or a time later than the latest send time.
        try await chat.updateScheduledMessage(
            id: scheduledMessageId,
            text: "Happy birthday, John!",
            scheduledAt: newScheduledAt
        )

        // Only the send time
        try await chat.rescheduleMessage(id: scheduledMessageId, scheduledAt: newScheduledAt)
    }

    func sendingAScheduledMessageNow() {
        // With the channel controller or the scheduled message list controller.
        // Marks the message on the device and sends it once its changes are on the
        // server. The message leaves the scheduled message list once it is sent.
        channelController.sendScheduledMessageNow(id: scheduledMessageId) { error in
            // An error means it was refused on the device, for example because its
            // quoted message was deleted. Remove the quote and try again.
            if let error {
                print("Couldn't send the scheduled message: \(error)")
            }
        }
    }

    func sendingAScheduledMessageNowAsync() async throws {
        // With Chat or ScheduledMessageList.
        // Marks the message on the device and sends it once its changes are on the
        // server. The message leaves the scheduled message list once it is sent.
        // It throws when it is refused on the device, for example because its quoted
        // message was deleted. Remove the quote and try again.
        try await chat.sendScheduledMessageNow(id: scheduledMessageId)
    }

    func deletingAScheduledMessage() {
        // With the channel controller or the scheduled message list controller. Unlike
        // the other changes, deleting waits for the server.
        channelController.deleteScheduledMessage(id: scheduledMessageId) { error in
            if let error {
                print("Failed to delete the scheduled message: \(error)")
            }
        }
    }

    func deletingAScheduledMessageAsync() async throws {
        // With Chat or ScheduledMessageList. Unlike the other changes, deleting waits
        // for the server.
        try await chat.deleteScheduledMessage(id: scheduledMessageId)
    }

    func queryingScheduledMessages() {
        // All the user's scheduled messages, across channels. The delegate is called
        // with controller.scheduledMessages whenever they change.
        let controller = chatClient.scheduledMessageListController()
        controller.delegate = self
        controller.synchronize()

        // Next page
        if !controller.hasLoadedAllScheduledMessages {
            controller.loadMoreScheduledMessages()
        }

        // Only one channel
        let channelQuery = ScheduledMessageListQuery(
            filter: .equal(.cid, to: ChannelId(type: .messaging, id: "general"))
        )
        let oneChannelController = chatClient.scheduledMessageListController(query: channelQuery)
        oneChannelController.delegate = self
        oneChannelController.synchronize()
    }

    func queryingScheduledMessagesAsync() async throws {
        // All the user's scheduled messages, across channels
        let scheduledMessageList = chatClient.makeScheduledMessageList()
        try await scheduledMessageList.get()
        print(scheduledMessageList.state.scheduledMessages)

        // Next page
        try await scheduledMessageList.loadMoreScheduledMessages()

        // Only one channel
        let channelQuery = ScheduledMessageListQuery(
            filter: .equal(.cid, to: ChannelId(type: .messaging, id: "general"))
        )
        let oneChannelList = chatClient.makeScheduledMessageList(with: channelQuery)
        try await oneChannelList.get()
    }

    func includingScheduledMessagesInChannelState() {
        // One channel: channelController.channel?.scheduledMessages holds the user's
        // scheduled messages in it
        var query = ChannelQuery(cid: ChannelId(type: .messaging, id: "general"))
        query.includeScheduledMessages = true
        let channelController = chatClient.channelController(for: query)
        channelController.synchronize()

        // A page of channels
        var channelListQuery = ChannelListQuery(filter: .containMembers(userIds: [currentUserId]))
        channelListQuery.includeScheduledMessages = true
        let channelListController = chatClient.channelListController(query: channelListQuery)
        channelListController.synchronize()
    }

    func includingScheduledMessagesInChannelStateAsync() async throws {
        // One channel
        var query = ChannelQuery(cid: ChannelId(type: .messaging, id: "general"))
        query.includeScheduledMessages = true
        let chat = chatClient.makeChat(with: query)
        try await chat.get(watch: true)
        // The user's scheduled messages in this channel
        print(chat.state.channel?.scheduledMessages ?? [])

        // A page of channels
        var channelListQuery = ChannelListQuery(filter: .containMembers(userIds: [currentUserId]))
        channelListQuery.includeScheduledMessages = true
        let channelList = chatClient.makeChannelList(with: channelListQuery)
        try await channelList.get()
    }

    func keepingScheduledMessagesInSyncOnTheClient() {
        // The list observes the local database, so it shows the changes made on the
        // device right away.

        let controller = chatClient.scheduledMessageListController(
            query: ScheduledMessageListQuery(filter: .equal(.cid, to: channelId))
        )
        controller.delegate = self
        controller.synchronize()

        // Or with Combine
        controller.scheduledMessagesChangesPublisher
            .sink { scheduledMessages in
                print(scheduledMessages)
            }
            .store(in: &cancellables)

        // When the server rejects a change, the status is .failed and `failure` says
        // why. Send the change again when it can be retried, otherwise change or delete
        // the message.
        for scheduledMessage in controller.scheduledMessages {
            if scheduledMessage.status == .failed, scheduledMessage.failure?.isRetryable == true {
                controller.resendScheduledMessage(id: scheduledMessage.id)
            }
        }
    }

    func keepingScheduledMessagesInSyncOnTheClientAsync() async throws {
        // The list observes the local database, so it shows the changes made on the
        // device right away.

        let scheduledMessageList = chatClient.makeScheduledMessageList(
            with: ScheduledMessageListQuery(filter: .equal(.cid, to: channelId))
        )
        try await scheduledMessageList.get()

        // ScheduledMessageListState is an ObservableObject
        scheduledMessageList.state.$scheduledMessages
            .sink { scheduledMessages in
                // Thread replies have a parent message
                let forChannel = scheduledMessages.filter { $0.message.parentMessageId == nil }
                let forThread = scheduledMessages.filter { $0.message.parentMessageId == parentMessageId }
                suppressUnusedWarning(forChannel, forThread)
            }
            .store(in: &cancellables)

        // When the server rejects a change, the status is .failed and `failure` says
        // why. Send the change again when it can be retried, otherwise change or delete
        // the message.
        for scheduledMessage in scheduledMessageList.state.scheduledMessages {
            if scheduledMessage.status == .failed, scheduledMessage.failure?.isRetryable == true {
                try await scheduledMessageList.resendScheduledMessage(id: scheduledMessage.id)
            }
        }
    }

    func events() {
        let sentCancellable = chatClient.subscribe(toEvent: ScheduledMessageSentEvent.self) { event in
            print("\(event.scheduledMessage.id) was sent as \(event.messageId)")
        }

        let failedCancellable = chatClient.subscribe(toEvent: ScheduledMessageFailedEvent.self) { event in
            if case let .serverFailedPublishing(failure) = event.scheduledMessage.failure {
                print(failure.reason?.rawValue ?? "unknown")
            }
        }
        suppressUnusedWarning(sentCancellable, failedCancellable)
    }
}

extension Snippets_04_12_ScheduledMessages: ChatChannelControllerDelegate {
    // The server's answer updates channel.scheduledMessages, which holds the user's
    // scheduled messages in the channel, and didUpdateChannel is called whenever
    // one of them changes, on the device or from the server.
    func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        for scheduledMessage in channel.item.scheduledMessages {
            switch scheduledMessage.failure {
            case let .serverRejectedScheduling(rejection):
                // The server refused the change, for example because the channel
                // limit was reached. The message describes it, with the limit.
                print("Couldn't schedule \(scheduledMessage.id): \(rejection.message)")
            case let .serverFailedPublishing(failure):
                // The server couldn't send it at its time, for example because the
                // user was banned. It can only be deleted.
                print("Couldn't send \(scheduledMessage.id): \(failure.reason?.rawValue ?? "unknown")")
            default:
                break
            }
        }
    }
}

extension Snippets_04_12_ScheduledMessages: ScheduledMessageListControllerDelegate {
    func controller(
        _ controller: ScheduledMessageListController,
        didChangeScheduledMessages scheduledMessages: [ScheduledMessage]
    ) {
        // Thread replies have a parent message
        let forChannel = scheduledMessages.filter { $0.message.parentMessageId == nil }
        let forThread = scheduledMessages.filter { $0.message.parentMessageId == parentMessageId }
        suppressUnusedWarning(forChannel, forThread)
    }
}
