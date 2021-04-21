//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserChannelBanEventMiddleware` events and updates `MemberDTO` accordingly.
struct UserChannelBanEventsMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        // Check if we have `cid` first. If `cid` is not presented the ban events are global bans and
        // they are already handled by `EventDataProcessorMiddleware`
        guard
            let eventPayload = (event as? EventWithPayload)?.payload as? EventPayload<ExtraData>,
            let cid = eventPayload.cid
        else {
            return event
        }
        
        do {
            switch event {
            case let userBannedEvent as UserBannedEvent:
                guard let memberDTO = session.member(userId: userBannedEvent.userId, cid: cid) else {
                    throw ClientError.MemberDoesNotExist(userId: userBannedEvent.userId, cid: cid)
                }
                
                memberDTO.isBanned = true
                memberDTO.banExpiresAt = userBannedEvent.expiredAt
                
            case let userUnbannedEvent as UserUnbannedEvent:
                guard let memberDTO = session.member(userId: userUnbannedEvent.userId, cid: cid) else {
                    throw ClientError.MemberDoesNotExist(userId: userUnbannedEvent.userId, cid: cid)
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
