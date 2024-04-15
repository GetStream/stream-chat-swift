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

extension ThreadReadDTO {
    func asModel() throws -> ThreadRead {
        try .init(
            user: user.asModel(),
            lastReadAt: lastReadAt?.bridgeDate,
            unreadMessagesCount: Int(unreadMessagesCount)
        )
    }
}
