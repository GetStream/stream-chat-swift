//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

class PollsRepository: @unchecked Sendable {
    let database: DatabaseContainer
    let apiClient: APIClient
    
    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }
    
    func createPoll(
        name: String,
        allowAnswers: Bool?,
        allowUserSuggestedOptions: Bool?,
        description: String?,
        enforceUniqueVote: Bool?,
        maxVotesAllowed: Int?,
        votingVisibility: String?,
        options: [PollOption]?,
        custom: [String: RawJSON]?,
        completion: @escaping @Sendable (Result<PollPayload, Error>) -> Void
    ) {
        let request = CreatePollRequestBody(
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            custom: custom,
            description: description,
            enforceUniqueVote: enforceUniqueVote,
            maxVotesAllowed: maxVotesAllowed,
            name: name,
            options: options?.compactMap { PollOptionRequestBody(text: $0.text, custom: $0.extraData) },
            votingVisibility: votingVisibility.flatMap { CreatePollRequest.CreatePollRequestVotingVisibility(rawValue: $0) }
        )
        apiClient.request(
            endpoint: Endpoint<PollResponse>.createPoll(createPollRequest: request)
        ) { (result: Result<PollPayloadResponse, Error>) in
            switch result {
            case let .success(response):
                completion(.success(response.poll))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func castPollVote(
        messageId: MessageId,
        pollId: String,
        answerText: String?,
        optionId: String?,
        currentUserId: String?,
        query: PollVoteListQuery?,
        deleteExistingVotes: [PollVote],
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        guard let optionId, !optionId.isEmpty else {
            // No optimistic updates for answers.
            let request = CastPollVoteRequestBody(
                pollId: pollId,
                vote: .init(
                    answerText: answerText,
                    optionId: optionId,
                    option: nil
                )
            )
            apiClient.request(
                endpoint: Endpoint<PollVoteResponse>.castPollVote(
                    messageId: messageId,
                    pollId: pollId,
                    castPollVoteRequest: request
                )
            ) {
                completion?($0.error)
            }
            return
        }
        
        nonisolated(unsafe) var pollVote: PollVote?
        database.write { session in
            let voteId = PollVoteDTO.localVoteId(optionId: optionId, pollId: pollId, userId: currentUserId)
            let existing = try? session.pollVote(id: voteId, pollId: pollId)
            if existing == nil {
                pollVote = try session.savePollVote(
                    voteId: nil,
                    pollId: pollId,
                    optionId: optionId,
                    answerText: answerText,
                    userId: currentUserId,
                    query: query
                )
                .asModel()
            } else {
                throw ClientError.PollVoteAlreadyExists()
            }
            for toDelete in deleteExistingVotes {
                _ = try? session.removePollVote(with: toDelete.id, pollId: toDelete.pollId)
            }
        } completion: { [weak self] error in
            if let error {
                completion?(error)
                return
            }
            let request = CastPollVoteRequestBody(
                pollId: pollId,
                vote: .init(
                    answerText: answerText,
                    optionId: optionId,
                    option: nil
                )
            )
            self?.apiClient.request(
                endpoint: Endpoint<PollVoteResponse>.castPollVote(
                    messageId: messageId,
                    pollId: pollId,
                    castPollVoteRequest: request
                )
            ) { [weak self] in
                if $0.isError, $0.error?.isBackendErrorWith400StatusCode == false, let pollVote {
                    self?.database.write { session in
                        _ = try? session.removePollVote(with: pollVote.id, pollId: pollVote.pollId)
                        for vote in deleteExistingVotes {
                            _ = try? session.savePollVote(
                                voteId: vote.id,
                                pollId: vote.pollId,
                                optionId: vote.optionId,
                                answerText: vote.answerText,
                                userId: vote.user?.id,
                                query: query
                            )
                        }
                    }
                }
                completion?($0.error)
            }
        }
    }
    
    func removePollVote(
        messageId: MessageId,
        pollId: String,
        voteId: String,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        nonisolated(unsafe) var exists = false
        nonisolated(unsafe) var answerText: String?
        nonisolated(unsafe) var optionId: String?
        nonisolated(unsafe) var userId: UserId?
        nonisolated(unsafe) var filterHash: String?
        database.write { session in
            let voteDto = try session.removePollVote(with: voteId, pollId: pollId)
            exists = voteDto != nil
            filterHash = voteDto?.queries?.first?.filterHash
            answerText = voteDto?.answerText
            optionId = voteDto?.optionId
            userId = voteDto?.user?.id
        } completion: { [weak self] error in
            if error == nil {
                self?.apiClient.request(
                    endpoint: Endpoint<PollVoteResponse>.deletePollVote(
                        messageId: messageId,
                        pollId: pollId,
                        voteId: voteId,
                        userId: nil
                    )
                ) { [weak self] in
                    if $0.error != nil, $0.error?.isBackendNotFound404StatusCode == false, exists {
                        self?.database.write { session in
                            _ = try session.savePollVote(
                                voteId: voteId,
                                pollId: pollId,
                                optionId: optionId,
                                answerText: answerText,
                                userId: userId,
                                query: nil
                            )
                            try? session.linkVote(with: voteId, in: pollId, to: filterHash)
                        }
                    }
                    completion?($0.error)
                }
            } else {
                completion?(error)
            }
        }
    }
    
    func closePoll(
        pollId: String,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        let request = UpdatePollPartialRequestBody(
            pollId: pollId,
            set: ["is_closed": .bool(true)]
        )
        apiClient.request(
            endpoint: Endpoint<PollResponse>.updatePollPartial(pollId: pollId, updatePollPartialRequest: request)
        ) {
            completion?($0.error)
        }
    }

    func deletePoll(
        pollId: String,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: Endpoint<Response>.deletePoll(pollId: pollId, userId: nil)
        ) { [weak self] in
            if $0.error == nil {
                self?.database.write { session in
                    _ = try? session.deletePoll(pollId: pollId)
                }
            }
            completion?($0.error)
        }
    }
    
    func suggestPollOption(
        pollId: String,
        text: String,
        position: Int? = nil,
        custom: [String: RawJSON]? = nil,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        let request = CreatePollOptionRequestBody(
            pollId: pollId,
            text: text,
            position: position,
            custom: custom
        )
        apiClient.request(
            endpoint: Endpoint<PollOptionResponseOpenAPI>.createPollOption(pollId: pollId, createPollOptionRequest: request),
            completion: {
                completion?($0.error)
            }
        )
    }
    
    func queryPollVotes(
        query: PollVoteListQuery,
        completion: (@Sendable (Result<VotePaginationResponse, Error>) -> Void)? = nil
    ) {
        let request = QueryPollVotesRequest(
            filter: nil,
            limit: query.pagination.pageSize,
            next: nil,
            prev: nil,
            sort: query.sorting.map { SortParamRequestOpenAPI(direction: $0.isAscending ? 1 : -1, field: $0.key.rawValue) }
        )
        apiClient.request(
            endpoint: Endpoint<PollVotesResponse>.queryPollVotes(pollId: query.pollId, userId: nil, queryPollVotesRequest: request)
        ) { [weak self] (result: Result<PollVoteListResponse, Error>) in
            switch result {
            case let .success(payload):
                nonisolated(unsafe) var votes: [PollVote] = []
                self?.database.write({ session in
                    votes = try session.savePollVotes(payload: payload, query: query, cache: nil).map { try $0.asModel() }
                }, completion: { error in
                    if let error = error {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(.init(votes: votes, next: payload.next)))
                    }
                })
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }
    
    func queryPollVotes(
        pollId: String,
        limit: Int?,
        next: String?,
        prev: String?,
        sort: [SortParamRequest?],
        filter: [String: RawJSON]?,
        completion: (@Sendable (Result<PollVoteListResponse, Error>) -> Void)? = nil
    ) {
        let sort = sort.compactMap { $0 }
        let request = QueryPollVotesRequestBody(
            filter: filter,
            limit: limit,
            next: next,
            prev: prev,
            sort: sort.isEmpty ? nil : sort
        )
        apiClient.request(
            endpoint: Endpoint<PollVotesResponse>.queryPollVotes(pollId: pollId, userId: nil, queryPollVotesRequest: request),
            completion: { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(response):
                    self.database.write { session in
                        for payload in response.votes {
                            try session.savePollVote(payload: payload, query: nil, cache: nil)
                        }
                    } completion: { _ in
                        completion?(result)
                    }
                case let .failure(error):
                    completion?(.failure(error))
                }
            }
        )
    }
    
    func link(pollVote: PollVote, to query: PollVoteListQuery) {
        database.write { session in
            try session.linkVote(
                with: pollVote.id,
                in: pollVote.pollId,
                to: query.queryHash
            )
        }
    }
    
    struct VotePaginationResponse {
        var votes: [PollVote]
        var next: String?
    }
}

extension ClientError {
    final class PollDoesNotExist: ClientError, @unchecked Sendable {
        init(pollId: String) {
            super.init("There is no `PollDTO` instance in the DB matching id: \(pollId).")
        }
    }
    
    final class PollOptionDoesNotExist: ClientError, @unchecked Sendable {
        init(optionId: String) {
            super.init("There is no `PollOptionDTO` instance in the DB matching id: \(optionId).")
        }
    }
    
    final class PollVoteDoesNotExist: ClientError, @unchecked Sendable {
        init(voteId: String) {
            super.init("There is no `PollVoteDTO` instance in the DB matching id: \(voteId).")
        }
    }
    
    public final class PollVoteAlreadyExists: ClientError, @unchecked Sendable {
        public init() {
            super.init("There is already `PollVoteDTO` instance in the DB.")
        }
    }
    
    final class InvalidInput: ClientError, @unchecked Sendable {
        init() {
            super.init("Invalid input provided to the method")
        }
    }
}
