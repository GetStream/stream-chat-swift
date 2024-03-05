//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct OrderedUsers {
    let cid: ChannelId
    let orderedUsers: [ChatUser]
    let sortDescriptors: [NSSortDescriptor]
    
    init(cid: ChannelId, orderedWatchers: [ChatUser]) {
        self.cid = cid
        orderedUsers = orderedWatchers
        sortDescriptors = UserDTO.watcherFetchRequest(cid: cid).sortDescriptors ?? []
    }
    
    func withListChanges(_ changes: [ListChange<ChatUser>]) -> [ChatUser] {
        orderedUsers.uniquelyApplied(changes, sortDescriptors: sortDescriptors)
    }
    
    func withInsertingPaginated(_ newSortedUsers: [ChatUser]) -> [ChatUser] {
        orderedUsers.uniquelyMerged(newSortedUsers, sortDescriptors: sortDescriptors)
    }
}
