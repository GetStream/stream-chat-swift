//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ThreadParticipantDTO)
class ThreadParticipantDTO: NSManagedObject {
    @NSManaged var createdAt: DBDate
    @NSManaged var lastReadAt: DBDate?
    @NSManaged var threadId: String
    @NSManaged var user: UserDTO
}

extension ThreadParticipantDTO {
    func asModel() throws -> ThreadParticipant {
        try .init(
            user: user.asModel(),
            threadId: threadId,
            createdAt: createdAt.bridgeDate,
            lastReadAt: lastReadAt?.bridgeDate
        )
    }
}
