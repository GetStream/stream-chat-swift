//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(CommandDTO)
final class CommandDTO: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var desc: String
    @NSManaged var set: String
    @NSManaged var args: String

    func asModel() throws -> Command {
        guard isValid else { throw InvalidModel(self) }
        return .init(
            name: name,
            description: desc,
            set: set,
            args: args
        )
    }
}

extension Command {
    func asDTO(context: NSManagedObjectContext) -> CommandDTO {
        let dto = CommandDTO(context: context)
        dto.name = name
        dto.desc = description
        dto.set = set
        dto.args = args
        return dto
    }
}
