//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(LocationDTO)
class LocationDTO: NSManagedObject {
    @NSManaged var messageId: String
    @NSManaged var channelId: String
    @NSManaged var deviceId: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var endAt: DBDate?
    @NSManaged var message: MessageDTO
}
