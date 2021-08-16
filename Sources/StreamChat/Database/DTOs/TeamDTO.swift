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

extension NSManagedObjectContext {
    func saveTeam(teamId: TeamId) throws -> TeamDTO {
        let dto = TeamDTO.loadOrCreate(teamId: teamId, context: self)

        dto.id = teamId
        return dto
    }
}

extension TeamDTO {
    static func load(teamId: TeamId, context: NSManagedObjectContext) -> TeamDTO? {
        let request = NSFetchRequest<TeamDTO>(entityName: TeamDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", teamId)
        return load(by: request, context: context).first
    }

    /// If a Team with the given id exists in the context, fetches and returns it. Otherwise create a new
    /// `TeamDTO` with the given id.
    ///
    /// - Parameters:
    ///   - teamId: Id of the team to be loaded or created.
    static func loadOrCreate(teamId: TeamId, context: NSManagedObjectContext) -> TeamDTO {
        if let existing = Self.load(teamId: teamId, context: context) {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! TeamDTO
        new.id = teamId
        return new
    }
}
