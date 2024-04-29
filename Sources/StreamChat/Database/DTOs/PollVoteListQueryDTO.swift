//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(PollVoteListQueryDTO)
class PollVoteListQueryDTO: NSManagedObject {
    /// Unique identifier of the query.
    @NSManaged var filterHash: String

    /// Serialized `Filter` JSON which can be used in cases the query needs to be repeated.
    @NSManaged var filterJSONData: Data

    // MARK: - Relationships

    @NSManaged var votes: Set<PollVoteDTO>

    static func load(filterHash: String, context: NSManagedObjectContext) -> PollVoteListQueryDTO? {
        load(
            keyPath: #keyPath(PollVoteListQueryDTO.filterHash),
            equalTo: filterHash,
            context: context
        ).first
    }

    static func loadOrCreate(filterHash: String, context: NSManagedObjectContext) -> PollVoteListQueryDTO {
        if let existing = load(filterHash: filterHash, context: context) {
            return existing
        }

        let request = fetchRequest(
            keyPath: #keyPath(PollVoteListQueryDTO.filterHash),
            equalTo: filterHash
        )
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.filterHash = filterHash
        return new
    }
}

extension NSManagedObjectContext {
    func pollVoteListQuery(filterHash: String) -> PollVoteListQueryDTO? {
        PollVoteListQueryDTO.load(filterHash: filterHash, context: self)
    }

    func saveQuery(query: PollVoteListQuery) throws -> PollVoteListQueryDTO? {
        guard let filterHash = query.filter?.filterHash else {
            // A query without a filter doesn't have to be saved to the DB because it matches all users by default.
            return nil
        }

        if let existingDTO = PollVoteListQueryDTO.load(filterHash: filterHash, context: self) {
            return existingDTO
        }

        let request = PollVoteListQueryDTO.fetchRequest(
            keyPath: #keyPath(PollVoteListQueryDTO.filterHash),
            equalTo: filterHash
        )
        let newDTO = NSEntityDescription.insertNewObject(into: self, for: request)
        newDTO.filterHash = filterHash

        do {
            newDTO.filterJSONData = try JSONEncoder.default.encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error).")
        }

        return newDTO
    }
}
