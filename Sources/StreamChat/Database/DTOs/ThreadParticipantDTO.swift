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
