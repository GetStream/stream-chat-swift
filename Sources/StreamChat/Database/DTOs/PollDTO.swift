//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(PollDTO)
class PollDTO: NSManagedObject {
    @NSManaged var allowAnswers: Bool
    @NSManaged var allowUserSuggestedOptions: Bool
    @NSManaged var answersCount: Int
    @NSManaged var createdAt: DBDate
    @NSManaged var pollDescription: String?
    @NSManaged var enforceUniqueVote: Bool
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var updatedAt: DBDate?
    @NSManaged var voteCount: Int
    @NSManaged var custom: Data?
    @NSManaged var voteCountsByOption: [String: Int]?
    @NSManaged var isClosed: Bool
    @NSManaged var maxVotesAllowed: NSNumber?
    @NSManaged var votingVisibility: String?
    @NSManaged var createdBy: UserDTO?
    @NSManaged var latestAnswers: Set<PollVoteDTO>
    @NSManaged var message: MessageDTO?
    @NSManaged var options: NSOrderedSet
    @NSManaged var latestVotesByOption: Set<PollOptionDTO>
    
    static func loadOrCreate(
        pollId: String,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> PollDTO {
        if let cachedObject = cache?.model(for: pollId, context: context, type: PollDTO.self) {
            return cachedObject
        }
        
        let request = fetchRequest(for: pollId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = pollId
        return new
    }
    
    static func load(pollId: String, context: NSManagedObjectContext) -> PollDTO? {
        let request = fetchRequest(for: pollId)
        return load(by: request, context: context).first
    }
    
    static func fetchRequest(for pollId: String) -> NSFetchRequest<PollDTO> {
        let request = NSFetchRequest<PollDTO>(entityName: PollDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PollDTO.updatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", pollId)
        return request
    }
}

extension PollDTO {
    func asModel() throws -> Poll {
        var extraData: [String: RawJSON] = [:]
        if let custom,
           !custom.isEmpty,
           let decoded = try? JSONDecoder.default.decode([String: RawJSON].self, from: custom) {
            extraData = decoded
        }
        
        let optionsArray = (options.array as? [PollOptionDTO]) ?? []
        
        return try Poll(
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            answersCount: answersCount,
            createdAt: createdAt.bridgeDate,
            pollDescription: pollDescription,
            enforceUniqueVote: enforceUniqueVote,
            id: id,
            name: name,
            updatedAt: updatedAt?.bridgeDate,
            voteCount: voteCount,
            extraData: extraData,
            voteCountsByOption: voteCountsByOption,
            isClosed: isClosed,
            maxVotesAllowed: maxVotesAllowed?.intValue,
            votingVisibility: votingVisibility(from: votingVisibility),
            createdBy: createdBy?.asModel(),
            latestAnswers: latestAnswers.map { try $0.asModel() },
            options: optionsArray.map { try $0.asModel() },
            latestVotesByOption: latestVotesByOption.map { try $0.asModel() }
        )
    }
    
    private func votingVisibility(from string: String?) -> VotingVisibility? {
        guard let string else { return nil }
        return VotingVisibility(rawValue: string)
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func savePoll(payload: PollPayload, cache: PreWarmedCache?) throws -> PollDTO {
        let pollDto = PollDTO.loadOrCreate(pollId: payload.id, context: self, cache: cache)
        
        pollDto.allowAnswers = payload.allowAnswers
        pollDto.allowUserSuggestedOptions = payload.allowUserSuggestedOptions
        pollDto.answersCount = payload.answersCount
        pollDto.createdAt = payload.createdAt.bridgeDate
        pollDto.pollDescription = payload.description
        pollDto.enforceUniqueVote = payload.enforceUniqueVote
        pollDto.name = payload.name
        pollDto.updatedAt = payload.updatedAt.bridgeDate
        pollDto.voteCount = payload.voteCount
        pollDto.custom = try JSONEncoder.default.encode(payload.custom)
        pollDto.voteCountsByOption = payload.voteCountsByOption
        pollDto.isClosed = payload.isClosed ?? false
        if let maxVotesAllowed = payload.maxVotesAllowed {
            pollDto.maxVotesAllowed = NSNumber(value: maxVotesAllowed)
        }
        pollDto.votingVisibility = payload.votingVisibility
        
        if let userPayload = payload.createdBy {
            pollDto.createdBy = try saveUser(payload: userPayload, query: nil, cache: cache)
        } else {
            pollDto.createdBy = UserDTO.loadOrCreate(id: payload.createdById, context: self, cache: cache)
        }
        pollDto.options = try NSOrderedSet(
            array: payload.options.compactMap { payload in
                if let payload {
                    let optionDto = try savePollOption(
                        payload: payload,
                        pollId: payload.id,
                        cache: cache
                    )
                    optionDto.poll = pollDto
                    return optionDto
                } else {
                    return nil
                }
            }
        )
        pollDto.latestVotesByOption = try Set(
            payload.latestVotesByOption?.compactMap { optionId, votesByOption in
                let optionDto = PollOptionDTO.loadOrCreate(
                    pollId: payload.id,
                    optionId: optionId,
                    context: self,
                    cache: cache
                )
                optionDto.poll = pollDto
                optionDto.latestVotes = Set(
                    try votesByOption.compactMap { vote in
                        let voteDto = try savePollVote(payload: vote, query: nil, cache: cache)
                        voteDto.option = optionDto
                        voteDto.poll = pollDto
                        return voteDto
                    }
                )
                
                return optionDto
            } ?? []
        )
        pollDto.latestAnswers = try Set(
            payload.latestAnswers?.compactMap { payload in
                if let payload {
                    let answerDto = try savePollVote(payload: payload, query: nil, cache: cache)
                    answerDto.poll = pollDto
                    return answerDto
                } else {
                    return nil
                }
            } ?? []
        )
        
        return pollDto
    }
    
    func poll(id: String) throws -> PollDTO? {
        PollDTO.load(pollId: id, context: self)
    }
}
