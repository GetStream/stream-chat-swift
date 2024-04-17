//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func createPoll(createPollRequest: CreatePollRequestBody) -> Endpoint<PollPayload> {
        .init(
            path: .polls,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: createPollRequest
        )
    }
    
    static func updatePoll(updatePollRequest: UpdatePollRequestBody) -> Endpoint<PollPayload> {
        .init(
            path: .polls,
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: updatePollRequest
        )
    }
    
    static func queryPolls(queryPollsRequest: QueryPollsRequestBody) -> Endpoint<QueryPollsPayload> {
        .init(
            path: .pollsQuery,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: queryPollsRequest
        )
    }
    
    static func deletePoll(pollId: String) -> Endpoint<EmptyResponse> {
        .init(
            path: .poll(pollId: pollId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )
    }
    
    static func getPoll(pollId: String) -> Endpoint<PollPayload> {
        .init(
            path: .poll(pollId: pollId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )
    }
    
    static func updatePollPartial(
        pollId: String,
        updatePollPartialRequest: UpdatePollPartialRequestBody
    ) -> Endpoint<PollPayload> {
        .init(
            path: .poll(pollId: pollId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: updatePollPartialRequest
        )
    }
    
    static func createPollOption(
        pollId: String,
        createPollOptionRequest: CreatePollOptionRequestBody
    ) -> Endpoint<PollOptionResponse> {
        .init(
            path: .pollOptions(pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: createPollOptionRequest
        )
    }
    
    static func updatePollOption(
        pollId: String,
        updatePollOptionRequest: UpdatePollOptionRequest
    ) -> Endpoint<PollOptionResponse> {
        .init(
            path: .pollOptions(pollId: pollId),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: updatePollOptionRequest
        )
    }
    
    static func deletePollOption(pollId: String, optionId: String) -> Endpoint<EmptyResponse> {
        .init(
            path: .pollOption(pollId: pollId, optionId: optionId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )
    }
    
    static func getPollOption(pollId: String, optionId: String) -> Endpoint<PollOptionResponse> {
        .init(
            path: .pollOption(pollId: pollId, optionId: optionId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )
    }
    
    static func queryPollVotes(
        pollId: String,
        queryPollVotesRequest: QueryPollVotesRequestBody
    ) -> Endpoint<PollVotesResponse> {
        .init(
            path: .pollVotes(pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: queryPollVotesRequest
        )
    }
    
    static func castPollVote(
        messageId: MessageId,
        pollId: String,
        vote: CastPollVoteRequestBody
    ) -> Endpoint<PollVotePayload> {
        .init(
            path: .pollVoteInMessage(messageId: messageId, pollId: pollId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: vote
        )
    }
    
    static func removePollVote(
        messageId: String,
        pollId: String,
        voteId: String
    ) -> Endpoint<PollVotePayload> {
        .init(
            path: .pollVote(messageId: messageId, pollId: pollId, voteId: voteId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )
    }
}
