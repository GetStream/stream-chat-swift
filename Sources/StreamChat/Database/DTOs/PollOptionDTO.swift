//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(PollOptionDTO)
class PollOptionDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var text: String
    @NSManaged var custom: Data?
    @NSManaged var poll: PollDTO?
    
    // It contains both latestAnswers and ownVotes, plus every other vote.
    // We can't have separate properties unless they have different entities.
    // So the only way it would work would be to add a new PollAnswerDTO entity.
    @NSManaged var latestVotes: Set<PollVoteDTO>
    
    static func loadOrCreate(
        pollId: String,
        optionId: String,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> PollOptionDTO {
        if let cachedObject = cache?.model(for: optionId, context: context, type: PollOptionDTO.self) {
            return cachedObject
        }
        
        let request = fetchRequest(for: optionId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = optionId
        return new
    }
    
    static func load(optionId: String, context: NSManagedObjectContext) -> PollOptionDTO? {
        let request = fetchRequest(for: optionId)
        return load(by: request, context: context).first
    }
    
    static func fetchRequest(for optionId: String) -> NSFetchRequest<PollOptionDTO> {
        let request = NSFetchRequest<PollOptionDTO>(entityName: PollOptionDTO.entityName)
        PollOptionDTO.applyPrefetchingState(to: request)
        request.predicate = NSPredicate(format: "id == %@", optionId)
        return request
    }
}

extension PollOptionDTO {
    override class func prefetchedRelationshipKeyPaths() -> [String] {
        [KeyPath.string(\PollOptionDTO.latestVotes)]
    }
}

extension PollOptionDTO {
    func asModel() throws -> PollOption {
        try isNotDeleted()
        
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.stream.decodeRawJSON(from: custom)
        } catch {
            log.error(
                "Failed to decode extra data for poll option with id: <\(id)>, using default value instead. Error: \(error)"
            )
            extraData = [:]
        }
        return PollOption(
            id: id,
            text: text,
            latestVotes: try latestVotes
                .map { try $0.asModel() }
                .sorted(by: { $0.createdAt > $1.createdAt }),
            extraData: extraData
        )
    }
}

extension NSManagedObjectContext {
    func savePollOption(
        payload: PollOptionPayload,
        pollId: String,
        cache: PreWarmedCache?
    ) throws -> PollOptionDTO {
        let dto = PollOptionDTO.loadOrCreate(
            pollId: pollId,
            optionId: payload.id,
            context: self,
            cache: cache
        )
        dto.text = payload.text
        if let custom = payload.custom, !custom.isEmpty {
            dto.custom = try JSONEncoder.default.encode(custom)
        } else {
            dto.custom = nil
        }
        return dto
    }
    
    func option(id: String, pollId: String) throws -> PollOptionDTO? {
        PollOptionDTO.load(optionId: id, context: self)
    }
}
