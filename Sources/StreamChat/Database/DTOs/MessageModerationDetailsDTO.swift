//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageModerationDetailsDTO)
final class MessageModerationDetailsDTO: NSManagedObject {
    @NSManaged var originalText: String
    @NSManaged var action: String
}
