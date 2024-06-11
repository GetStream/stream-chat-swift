//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(BlockedUserDTO)
class BlockedUserDTO: NSManagedObject {
    @NSManaged var blockedUserId: String
    @NSManaged var blockedAt: DBDate?
    
    func asModel() throws -> BlockedUser {
        .init(
            userId: blockedUserId,
            blockedAt: blockedAt?.bridgeDate
        )
    }
}

extension BlockingUserPayload {
    func asDTO(context: NSManagedObjectContext) -> BlockedUserDTO {
        let dto = BlockedUserDTO(context: context)
        dto.blockedUserId = blockedUserId
        dto.blockedAt = createdAt.bridgeDate
        return dto
    }
}

extension BlockPayload {
    func asDTO(context: NSManagedObjectContext) -> BlockedUserDTO {
        let dto = BlockedUserDTO(context: context)
        dto.blockedUserId = blockedUserId
        dto.blockedAt = createdAt.bridgeDate
        return dto
    }
}
