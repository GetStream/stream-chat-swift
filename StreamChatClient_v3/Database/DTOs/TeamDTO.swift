//
// TeamDTO.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

// TODO: Finish implementation

@objc(TeamDTO)
class TeamDTO: NSManagedObject {
    @NSManaged fileprivate var id: String
    
    // MARK: - Relationships
    
    @NSManaged fileprivate var channels: Set<ChannelDTO>
    @NSManaged fileprivate var users: Set<UserDTO>
}
