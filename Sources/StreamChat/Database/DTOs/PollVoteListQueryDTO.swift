//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

extension PollVoteListQueryDTO {
    override class func prefetchedRelationshipKeyPaths() -> [String] {
        [KeyPath.string(\PollVoteListQueryDTO.votes)]
    }
}

extension NSManagedObjectContext {
    func linkVote(with id: String, in pollId: String, to filterHash: String?) throws {
        guard let filterHash else { throw ClientError.Unexpected() }
        let queryDto = pollVoteListQuery(filterHash: filterHash)
        if let vote = try pollVote(id: id, pollId: pollId) {
            queryDto?.votes.insert(vote)
        }
    }
    
    func pollVoteListQuery(filterHash: String) -> PollVoteListQueryDTO? {
        PollVoteListQueryDTO.load(filterHash: filterHash, context: self)
    }

    func saveQuery(query: PollVoteListQuery) throws -> PollVoteListQueryDTO? {
        if let existingDTO = PollVoteListQueryDTO.load(filterHash: query.queryHash, context: self) {
            return existingDTO
        }

        let request = PollVoteListQueryDTO.fetchRequest(
            keyPath: #keyPath(PollVoteListQueryDTO.filterHash),
            equalTo: query.queryHash
        )
        let newDTO = NSEntityDescription.insertNewObject(into: self, for: request)
        newDTO.filterHash = query.queryHash

        do {
            newDTO.filterJSONData = try JSONEncoder.default.encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error).")
        }

        return newDTO
    }
}
