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
            blockedUserId: blockedUserId,
            blockedAt: blockedAt?.bridgeDate ?? .init()
        )
    }
}

extension BlockedUserPayload {
    func asDTO(context: NSManagedObjectContext) -> BlockedUserDTO {
        let dto = BlockedUserDTO(context: context)
        dto.blockedUserId = blockedUserId
        dto.blockedAt = createdAt.bridgeDate
        return dto
    }
}