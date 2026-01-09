//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelFilterTagDTO)
class ChannelFilterTagDTO: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var channel: ChannelDTO?
}

