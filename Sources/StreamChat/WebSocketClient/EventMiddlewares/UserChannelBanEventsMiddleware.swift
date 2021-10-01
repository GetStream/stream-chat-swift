//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserChannelBanEventMiddleware` events and updates `MemberDTO` accordingly.
struct UserChannelBanEventsMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case let userBannedEvent as UserBannedEventDTO:
                guard let memberDTO = session.member(userId: userBannedEvent.user.id, cid: userBannedEvent.cid) else {
                    throw ClientError.MemberDoesNotExist(userId: userBannedEvent.user.id, cid: userBannedEvent.cid)
                }
                
                memberDTO.isBanned = true
                memberDTO.banExpiresAt = userBannedEvent.expiredAt
                
            case let userUnbannedEvent as UserUnbannedEventDTO:
                guard let memberDTO = session.member(userId: userUnbannedEvent.user.id, cid: userUnbannedEvent.cid) else {
                    throw ClientError.MemberDoesNotExist(userId: userUnbannedEvent.user.id, cid: userUnbannedEvent.cid)
                }
                
                memberDTO.isBanned = false
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
