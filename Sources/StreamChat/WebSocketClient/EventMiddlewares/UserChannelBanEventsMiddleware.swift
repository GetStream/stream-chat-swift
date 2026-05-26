//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserChannelBanEventMiddleware` events and updates `MemberDTO` accordingly.
struct UserChannelBanEventsMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case let userBannedEvent as UserBannedEventDTO:
                guard let cidString = userBannedEvent.cid, let cid = try? ChannelId(cid: cidString) else { break }
                guard let memberDTO = session.member(userId: userBannedEvent.user.id, cid: cid) else {
                    throw ClientError.MemberDoesNotExist(userId: userBannedEvent.user.id, cid: cid)
                }

                memberDTO.isBanned = true
                memberDTO.banExpiresAt = userBannedEvent.expiration?.bridgeDate

                if let isShadowBan = userBannedEvent.shadow {
                    memberDTO.isShadowBanned = isShadowBan
                }

            case let userUnbannedEvent as UserUnbannedEventDTO:
                guard let cidString = userUnbannedEvent.cid, let cid = try? ChannelId(cid: cidString) else { break }
                guard let memberDTO = session.member(userId: userUnbannedEvent.user.id, cid: cid) else {
                    throw ClientError.MemberDoesNotExist(userId: userUnbannedEvent.user.id, cid: cid)
                }

                memberDTO.isBanned = false
                memberDTO.isShadowBanned = false
                memberDTO.banExpiresAt = nil

            case let userMessagesDeletedEvent as UserMessagesDeletedEventDTO:
                let userId = userMessagesDeletedEvent.user.id
                if let userDTO = session.user(id: userId) {
                    userDTO.messages?.forEach { message in
                        if userMessagesDeletedEvent.hardDelete ?? false {
                            message.isHardDeleted = true
                        } else {
                            message.deletedAt = userMessagesDeletedEvent.createdAt.bridgeDate
                        }
                    }
                }

            default:
                break
            }
        } catch {
            log.error("Error handling `\(type(of: event))` event: \(error)")
        }

        return event
    }
}

extension ClientError {
    final class MemberDoesNotExist: ClientError, @unchecked Sendable {
        init(userId: UserId, cid: ChannelId) {
            super.init("There is no `MemberDTO` instance in the DB matching userId: \(userId) and cid: \(cid).")
        }
    }
}
