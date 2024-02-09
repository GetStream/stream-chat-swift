//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `MemberEvent`s and updates `ChannelDTO`s accordingly.
struct MemberEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case let event as StreamChatMemberUpdatedEvent:
                let cid = try ChannelId(cid: event.cid)
                if let member = event.member {
                    try session.saveMember(
                        payload: member,
                        channelId: cid,
                        query: nil,
                        cache: nil
                    )
                }

            case let event as StreamChatMemberAddedEvent:
                let cid = try ChannelId(cid: event.cid)
                if let channel = session.channel(cid: cid), let member = event.member {
                    let member = try session.saveMember(
                        payload: member,
                        channelId: cid,
                        query: nil,
                        cache: nil
                    )

                    insertMemberToMemberListQueries(channel, member)
                }

            case let event as StreamChatMemberRemovedEvent:
                guard let cid = try? ChannelId(cid: event.cid),
                      let channel = session.channel(cid: cid) else {
                    // No need to throw ChannelNotFound error here
                    break
                }

                guard let member = channel.members.first(where: { $0.user.id == event.user?.id }) else {
                    // No need to throw MemberNotFound error here
                    break
                }

                // Mark channel as unread
                if let user = event.user {
                    session.markChannelAsUnread(cid: cid, by: user.id)
                }

                // We remove the member from the channel
                channel.members.remove(member)
                if let membership = channel.membership, membership.user.id == event.user?.id {
                    channel.membership = nil
                }

                // If there are any MemberListQueries observing this channel,
                // we need to update them too
                member.queries.removeAll()

            case let event as StreamChatNotificationAddedToChannelEvent:
                guard let channelResponse = event.channel,
                      let cid = try? ChannelId(cid: channelResponse.cid),
                      let memberResponse = event.member else { return event }
                let channel = try session.saveChannel(
                    payload: channelResponse,
                    query: nil,
                    cache: nil
                )
                let member = try session.saveMember(
                    payload: memberResponse,
                    channelId: cid,
                    query: nil,
                    cache: nil
                )
                channel.membership = member

                insertMemberToMemberListQueries(channel, member)

            case let event as StreamChatNotificationRemovedFromChannelEvent:
                guard let cid = try? ChannelId(cid: event.cid),
                      let channel = session.channel(cid: cid) else {
                    // No need to throw ChannelNotFound error here
                    log.debug("Channel \(event.cid) not found for NotificationRemovedFromChannelEventDTO")
                    break
                }

                guard let member = channel.members.first(where: { $0.user.id == event.member?.userId }) else {
                    // No need to throw MemberNotFound error here
                    log.debug("Member \(event.member?.userId ?? "") not found for NotificationRemovedFromChannelEventDTO")
                    break
                }

                // We remove the member from the channel
                channel.members.remove(member)
                // We reset membership since we're no longer a member
                channel.membership = nil

                // If there are any MemberListQueries observing this channel,
                // we need to update them too
                member.queries.removeAll()

            case let event as StreamChatNotificationInviteAcceptedEvent:
                guard let channelPayload = event.channel,
                      let cid = try? ChannelId(cid: channelPayload.cid),
                      let memberPayload = event.member else { return event }
                let channel = try session.saveChannel(payload: channelPayload, query: nil, cache: nil)
                let member = try session.saveMember(
                    payload: memberPayload,
                    channelId: cid,
                    query: nil,
                    cache: nil
                )
                channel.membership = member

            case let event as StreamChatNotificationInviteRejectedEvent:
                guard let channelPayload = event.channel,
                      let cid = try? ChannelId(cid: channelPayload.cid),
                      let memberPayload = event.member else { return event }
                let channel = try session.saveChannel(payload: channelPayload, query: nil, cache: nil)
                let member = try session.saveMember(
                    payload: memberPayload,
                    channelId: cid,
                    query: nil,
                    cache: nil
                )
                channel.membership = member

            case let event as StreamChatNotificationInvitedEvent:
                guard let cid = try? ChannelId(cid: event.cid),
                      let channel = session.channel(cid: cid),
                      let memberPayload = event.member else {
                    // No need to throw ChannelNotFound error here
                    break
                }
                let member = try session.saveMember(
                    payload: memberPayload,
                    channelId: cid,
                    query: nil,
                    cache: nil
                )
                channel.membership = member

                insertMemberToMemberListQueries(channel, member)

            default:
                break
            }
        } catch {
            log.error("Failed to update channel members in the database, error: \(error)")
        }

        return event
    }

    private func insertMemberToMemberListQueries(_ channel: ChannelDTO, _ member: MemberDTO) {
        // If there are any `MemberListQuery`s observing this Channel
        // without any filters (so the query observes all members)
        // the new Member should be linked to them too
        // so `MemberListController` works as expected
        // To make it work with queries with filters, we need to mirror `ChannelListController` logic
        // `shouldListUpdatedChannel` and such
        channel.memberListQueries.filter { $0.filterJSONData == nil }.forEach {
            $0.members.insert(member)
        }
    }
}
