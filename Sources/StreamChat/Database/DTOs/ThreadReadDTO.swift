//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ThreadReadDTO)
class ThreadReadDTO: NSManagedObject {
    @NSManaged var user: UserDTO
    @NSManaged var lastReadAt: DBDate?
    @NSManaged var unreadMessagesCount: Int64
}
