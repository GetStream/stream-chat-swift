//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(PollVoteDTO)
class PollVoteDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var createdAt: DBDate
    @NSManaged var updatedAt: DBDate
    @NSManaged var pollId: String
    @NSManaged var optionId: String
    @NSManaged var isAnswer: Bool
    @NSManaged var answerText: String?
    @NSManaged var option: PollOptionDTO?
    @NSManaged var poll: PollDTO?
    @NSManaged var user: UserDTO?
    
    static func loadOrCreate(
        voteId: String,
        poll: PollDTO,
        option: PollOptionDTO,
        user: UserDTO,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> PollVoteDTO {
        let request = fetchRequest(for: voteId, pollId: poll.id)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = voteId
        new.option = option
        new.poll = poll
        new.user = user
        return new
    }
    
    static func fetchRequest(for voteId: String, pollId: String) -> NSFetchRequest<PollVoteDTO> {
        let request = NSFetchRequest<PollVoteDTO>(entityName: PollVoteDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@ && pollId == %@", voteId, pollId)
        return request
    }
}

extension PollVoteDTO {
    func asModel() throws -> PollVote {
        try PollVote(
            id: id,
            createdAt: createdAt.bridgeDate,
            updatedAt: updatedAt.bridgeDate,
            pollId: pollId,
            optionId: optionId,
            isAnswer: isAnswer,
            answerText: answerText,
            user: user?.asModel()
        )
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func savePollVotes(payload: PollVoteListResponse, query: PollVoteListQuery?, cache: PreWarmedCache?) -> [PollVoteDTO] {
        let isFirstPage = query?.pagination.offset == 0
        if let filterHash = query?.queryHash, isFirstPage {
            let queryDTO = PollVoteListQueryDTO.load(filterHash: filterHash, context: self)
            queryDTO?.votes = []
        }

        return payload.votes.compactMapLoggingError {
            if let payload = $0 {
                return try savePollVote(payload: payload, query: query, cache: cache)
            } else {
                return nil
            }
        }
    }
    
    @discardableResult
    func savePollVote(
        payload: PollVotePayload,
        query: PollVoteListQuery?,
        cache: PreWarmedCache?
    ) throws -> PollVoteDTO {
        guard let user = payload.user else { throw ClientError.UserDoesNotExist(userId: "") }
        guard let poll = try poll(id: payload.pollId),
              let option = try option(id: payload.optionId, pollId: payload.pollId) else {
            throw ClientError.Unexpected()
        }
        
        let dto = PollVoteDTO.loadOrCreate(
            voteId: payload.id,
            poll: poll,
            option: option,
            user: try saveUser(payload: user, query: nil, cache: cache),
            context: self,
            cache: cache
        )
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.pollId = payload.pollId
        dto.isAnswer = payload.isAnswer ?? false
        dto.answerText = payload.answerText
        dto.optionId = payload.optionId
        
        if let query = query {
            let queryDTO = try saveQuery(query: query)
            queryDTO?.votes.insert(dto)
        }
        
        return dto
    }
}

extension PollVoteDTO {
    static func pollVoteListFetchRequest(query: PollVoteListQuery) -> NSFetchRequest<PollVoteDTO> {
        let request = NSFetchRequest<PollVoteDTO>(entityName: PollVoteDTO.entityName)

        // Fetch results controller requires at least one sorting descriptor.
        // At the moment, we do not allow changing the query sorting.
        request.sortDescriptors = [.init(key: #keyPath(PollVoteDTO.createdAt), ascending: false)]

        // If a filter exists, use is for the predicate. Otherwise, `nil` filter matches all reactions.
        if let filterHash = query.filter?.filterHash {
            request.predicate = NSPredicate(format: "ANY queries.filterHash == %@", filterHash)
        }
            
        return request
    }
}
