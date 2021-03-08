//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

// TODO: Finish implementation

@objc(TeamDTO)
class TeamDTO: NSManagedObject {
    @NSManaged var id: String
    
    // MARK: - Relationships
    
    @NSManaged var channels: Set<ChannelDTO>
    @NSManaged var users: Set<UserDTO>
}
