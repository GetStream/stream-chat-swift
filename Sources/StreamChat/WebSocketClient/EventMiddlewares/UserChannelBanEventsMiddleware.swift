//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserChannelBanEventMiddleware` events and updates `MemberDTO` accordingly.
struct UserChannelBanEventsMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case let userBannedEvent as UserBannedEvent:
                guard let cid = try? ChannelId(cid: userBannedEvent.cid),
                      let userId = userBannedEvent.user?.id,
                      let memberDTO = session.member(userId: userId, cid: cid) else {
                    throw ClientError.Unknown()
                }

                memberDTO.isBanned = true
                memberDTO.banExpiresAt = userBannedEvent.expiration?.bridgeDate
                memberDTO.isShadowBanned = userBannedEvent.shadow

            case let userUnbannedEvent as UserUnbannedEvent:
                guard let cid = try? ChannelId(cid: userUnbannedEvent.cid),
                      let userId = userUnbannedEvent.user?.id,
                      let memberDTO = session.member(userId: userId, cid: cid) else {
                    throw ClientError.Unknown()
                }

                memberDTO.isBanned = false
                memberDTO.isShadowBanned = false
                memberDTO.banExpiresAt = nil

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
    class MemberDoesNotExist: ClientError {
        init(userId: UserId, cid: ChannelId) {
            super.init("There is no `MemberDTO` instance in the DB matching userId: \(userId) and cid: \(cid).")
        }
    }
}
