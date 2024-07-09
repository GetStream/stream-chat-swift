//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct ThreadUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as MessageReadEventDTO:
            if let threadDetails = event.payload.threadDetails?.value {
                session.markThreadAsRead(parentMessageId: threadDetails.parentMessageId, userId: event.user.id, at: event.createdAt)
            }
        case let event as NotificationMarkUnreadEventDTO:
            // At the moment, this event does not return the thread id, so
            // this is the only way to identify that this event is related to a thread
            let isUnreadThread = event.lastReadMessageId == nil
            if isUnreadThread {
                session.markThreadAsUnread(for: event.firstUnreadMessageId, userId: event.user.id)
            }
        case let event as MessageUpdatedEventDTO:
            guard let parentId = event.message.parentId else { break }
            guard let thread = session.thread(parentMessageId: parentId, cache: nil) else {
                break
            }
            // Trigger thread update if a thread reply's text was updated.
            if event.message.messageTextUpdatedAt != nil {
                thread.updatedAt = thread.updatedAt
            }
        case let event as MessageDeletedEventDTO:
            /// Parent message deleted
            if let thread = session.thread(parentMessageId: event.message.id, cache: nil) {
                if event.hardDelete {
                    // Delete the thread if parent message is hard deleted.
                    session.delete(thread: thread)
                } else {
                    // Trigger a thread update when parent from thread is soft deleted.
                    thread.updatedAt = thread.updatedAt
                }
                /// Thread reply deleted
            } else if let parentId = event.message.parentId,
                      let thread = session.thread(parentMessageId: parentId, cache: nil) {
                // Trigger a thread update when reply from thread is deleted.
                thread.updatedAt = thread.updatedAt
            }
        case let event as ChannelDeletedEventDTO:
            // Delete threads belonging to this deleted channel
            guard let channel = session.channel(cid: event.channel.cid) else { break }
            deleteThreads(for: channel, session: session)
        case let event as ChannelTruncatedEventDTO:
            // Delete threads belonging to this truncated channel
            guard let channel = session.channel(cid: event.channel.cid) else { break }
            deleteThreads(for: channel, session: session)
        case let event as ThreadMessageNewEventDTO:
            let messagePayload = event.message
            guard let channelId = event.message.cid,
                  let parentMessageId = messagePayload.parentId,
                  let channelDTO = session.channel(cid: channelId) else {
                break
            }
            guard let message = try? session.saveMessage(
                payload: messagePayload,
                channelDTO: channelDTO,
                syncOwnReactions: false,
                cache: nil
            )
            else {
                break
            }

            /// Add message to thread replies
            let thread = session.thread(parentMessageId: parentMessageId, cache: nil)
            thread?.latestReplies.insert(message)
            /// Trigger a thread update, but do not update the order of the thread list.
            /// This is why we don't change the `updatedAt` value.
            thread?.updatedAt = thread?.updatedAt

            guard let currentUser = session.currentUser else {
                break
            }

            /// Do not increase the unread count of the thread if the message is from the current user
            if message.user.id == currentUser.user.id {
                break
            }

            /// Do not increase the unread count if the message is from a muted user
            if currentUser.mutedUsers.map(\.id).contains(message.user.id) {
                break
            }

            session.incrementThreadUnreadCount(parentMessageId: parentMessageId, for: currentUser.user.id)
        default:
            break
        }
        return event
    }

    private func deleteThreads(for channel: ChannelDTO, session: DatabaseSession) {
        channel.threads.forEach {
            session.delete(thread: $0)
        }
    }
}
