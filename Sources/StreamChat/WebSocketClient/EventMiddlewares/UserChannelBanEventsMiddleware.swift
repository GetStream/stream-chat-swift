//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserChannelBanEventMiddleware` events and updates `MemberDTO` accordingly.
struct UserChannelBanEventsMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    let database: DatabaseContainer

    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        // Check if we have `cid` first. If `cid` is not presented the ban events are global bans and
        // they are already handled by `EventDataProcessorMiddleware`
        guard
            let eventPayload = (event as? EventWithPayload)?.payload as? EventPayload<ExtraData>,
            let cid = eventPayload.cid
        else {
            completion(event)
            return
        }

        switch event {
        case let userBannedEvent as UserBannedEvent:
            database.write { session in
                guard let memberDTO = session.member(userId: userBannedEvent.userId, cid: cid) else {
                    throw ClientError.MemberDoesNotExist(userId: userBannedEvent.userId, cid: cid)
                }

                memberDTO.isBanned = true
                memberDTO.banExpiresAt = userBannedEvent.expiredAt
            } completion: { error in
                if let error = error {
                    log.error("Failed to write `UserBannedEvent` updates to the DB: \(error)")
                }
                completion(event)
            }

        case let userUnbannedEvent as UserUnbannedEvent:
            database.write { session in
                guard let memberDTO = session.member(userId: userUnbannedEvent.userId, cid: cid) else {
                    throw ClientError.MemberDoesNotExist(userId: userUnbannedEvent.userId, cid: cid)
                }

                memberDTO.isBanned = false
                memberDTO.banExpiresAt = nil
            } completion: { error in
                if let error = error {
                    log.error("Failed to write `UserUnbannedEvent` updates to the DB: \(error)")
                }
                completion(event)
            }

        default:
            completion(event)
        }
    }
}

extension ClientError {
    class MemberDoesNotExist: ClientError {
        init(userId: UserId, cid: ChannelId) {
            super.init("There is no `MemberDTO` instance in the DB matching userId: \(userId) and cid: \(cid).")
        }
    }
}
