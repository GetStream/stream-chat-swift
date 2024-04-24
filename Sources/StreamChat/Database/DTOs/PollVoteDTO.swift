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
    @NSManaged var isAnswer: Bool
    @NSManaged var answerText: String?
    @NSManaged var option: PollOptionDTO?
    @NSManaged var poll: PollDTO?
    @NSManaged var user: UserDTO?
    
    static func loadOrCreate(
        voteId: String,
        pollId: String,
        optionId: String,
        userId: String,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> PollVoteDTO {
        let request = fetchRequest(for: voteId, pollId: pollId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.option = PollOptionDTO.loadOrCreate(
            pollId: pollId,
            optionId: optionId,
            context: context,
            cache: cache
        )
        new.user = UserDTO.loadOrCreate(id: userId, context: context, cache: cache)
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
            isAnswer: isAnswer,
            answerText: answerText,
            user: user?.asModel()
        )
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func savePollVote(
        payload: PollVotePayload,
        cache: PreWarmedCache?
    ) throws -> PollVoteDTO {
        guard let userId = payload.userId else { throw ClientError.UserDoesNotExist(userId: "") }
        let dto = PollVoteDTO.loadOrCreate(
            voteId: payload.id,
            pollId: payload.pollId,
            optionId: payload.optionId,
            userId: userId,
            context: self,
            cache: cache
        )
        dto.id = payload.id
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.pollId = payload.pollId
        dto.isAnswer = payload.isAnswer ?? false
        dto.answerText = payload.answerText
        return dto
    }
}
