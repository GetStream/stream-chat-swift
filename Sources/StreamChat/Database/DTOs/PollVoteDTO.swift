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
    @NSManaged var optionId: String?
    @NSManaged var isAnswer: Bool
    @NSManaged var answerText: String?
    @NSManaged var option: PollOptionDTO?
    @NSManaged var poll: PollDTO?
    @NSManaged var user: UserDTO?
    @NSManaged var queries: Set<PollVoteListQueryDTO>?
    
    static func loadOrCreate(
        voteId: String,
        poll: PollDTO,
        option: PollOptionDTO?,
        user: UserDTO?,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> PollVoteDTO {
        if let cachedObject = cache?.model(for: voteId, context: context, type: PollVoteDTO.self) {
            return cachedObject
        }
        
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
    
    static func load(voteId: String, pollId: String, context: NSManagedObjectContext) -> PollVoteDTO? {
        let request = fetchRequest(for: voteId, pollId: pollId)
        let results = load(by: request, context: context)
        return results.first
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
        guard let poll = try poll(id: payload.pollId) else {
            throw ClientError.PollDoesNotExist(pollId: payload.pollId)
        }
        
        var option: PollOptionDTO?
        if let optionId = payload.optionId, !optionId.isEmpty {
            option = try? self.option(id: optionId, pollId: payload.pollId)
        }
        
        var user: UserDTO?
        if let payloadUser = payload.user {
            user = try saveUser(payload: payloadUser, query: nil, cache: cache)
        }
        let dto = PollVoteDTO.loadOrCreate(
            voteId: payload.id,
            poll: poll,
            option: option,
            user: user,
            context: self,
            cache: cache
        )
        dto.option = option
        dto.poll = poll
        dto.user = user
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.pollId = payload.pollId
        dto.isAnswer = payload.isAnswer ?? false
        dto.answerText = payload.answerText
        dto.optionId = option?.id
        
        if let query = query {
            let queryDTO = try saveQuery(query: query)
            queryDTO?.votes.insert(dto)
        }
        
        return dto
    }
    
    @discardableResult
    func savePollVote(
        voteId: String?,
        pollId: String,
        optionId: String?,
        answerText: String?,
        userId: String?,
        query: PollVoteListQuery?
    ) throws -> PollVoteDTO {
        guard let poll = try poll(id: pollId) else {
            throw ClientError.PollDoesNotExist(pollId: pollId)
        }
        
        var option: PollOptionDTO?
        if let optionId {
            option = try? self.option(id: optionId, pollId: pollId)
        }
        
        var userDto: UserDTO?
        if let userId {
            userDto = user(id: userId)
        }
        let userId = userId ?? "anon"
        let voteId = voteId ?? PollVoteDTO.localVoteId(optionId: optionId, pollId: pollId, userId: userId)
        let dto = PollVoteDTO.loadOrCreate(
            voteId: voteId,
            poll: poll,
            option: option,
            user: userDto,
            context: self,
            cache: nil
        )
        
        dto.createdAt = Date().bridgeDate
        dto.updatedAt = Date().bridgeDate
        dto.pollId = pollId
        dto.isAnswer = answerText != nil
        dto.answerText = answerText
        dto.optionId = optionId
        
        if let optionId {
            let currentVoteCount = poll.voteCountsByOption?[optionId] ?? 0
            poll.voteCountsByOption?[optionId] = currentVoteCount + 1
            poll.latestAnswers.remove(dto)
        }
        
        if let query = query {
            let queryDTO = try saveQuery(query: query)
            queryDTO?.votes.insert(dto)
        }
        
        option?.latestVotes.insert(dto)
        
        return dto
    }
    
    func pollVotes(for userId: String, pollId: String) throws -> [PollVoteDTO] {
        let request = NSFetchRequest<PollVoteDTO>(entityName: PollVoteDTO.entityName)
        request.predicate = NSPredicate(format: "user.id == %@ && pollId == %@", userId, pollId)
        return PollVoteDTO.load(by: request, context: self)
    }
    
    func pollVote(id: String, pollId: String) throws -> PollVoteDTO? {
        PollVoteDTO.load(voteId: id, pollId: pollId, context: self)
    }
    
    func removePollVote(with id: String, pollId: String) throws -> PollVoteDTO? {
        guard let dto = try pollVote(id: id, pollId: pollId) else {
            throw ClientError.PollVoteDoesNotExist(voteId: id)
        }
        
        let poll = try? poll(id: pollId)
        if let optionId = dto.optionId {
            let votes = (poll?.voteCountsByOption?[optionId] ?? 0) - 1
            if votes >= 0 {
                poll?.voteCountsByOption?[optionId] = votes
            }
            dto.option?.latestVotes.remove(dto)
        }

        delete(pollVote: dto)
        return dto
    }
    
    func delete(pollVote: PollVoteDTO) {
        delete(pollVote)
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

extension PollVoteDTO {
    static func localVoteId(optionId: String?, pollId: String, userId: String?) -> String {
        if let optionId {
            return "\(optionId)-\(pollId)-\(userId ?? "anon")"
        } else {
            return "\(pollId)-\(userId ?? "anon")"
        }
    }
}
