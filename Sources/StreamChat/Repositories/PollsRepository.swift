//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

class PollsRepository {
    let database: DatabaseContainer
    let apiClient: APIClient
    
    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }
    
    func createPoll(
        name: String,
        allowAnswers: Bool? = nil,
        allowUserSuggestedOptions: Bool? = nil,
        description: String? = nil,
        enforceUniqueVote: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        votingVisibility: String? = nil,
        options: [PollOption]? = nil,
        custom: [String: RawJSON]? = nil,
        completion: @escaping (Result<PollPayload, Error>) -> Void
    ) {
        let request = CreatePollRequestBody(
            name: name,
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            description: description,
            enforceUniqueVote: enforceUniqueVote,
            maxVotesAllowed: maxVotesAllowed,
            votingVisibility: votingVisibility,
            options: options?.compactMap { PollOptionRequestBody(text: $0.text, custom: $0.custom) },
            custom: custom
        )
        apiClient.request(endpoint: .createPoll(createPollRequest: request)) { (result: Result<PollPayloadResponse, Error>) in
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
        completion: ((Error?) -> Void)? = nil
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
                endpoint: .castPollVote(
                    messageId: messageId,
                    pollId: pollId,
                    vote: request
                )
            ) {
                completion?($0.error)
            }
            return
        }
        
        var pollVote: PollVoteDTO?
        database.write { session in
            pollVote = try session.savePollVote(
                pollId: pollId,
                optionId: optionId,
                answerText: answerText,
                userId: currentUserId,
                query: query
            )
        } completion: { [weak self] _ in
            let request = CastPollVoteRequestBody(
                pollId: pollId,
                vote: .init(
                    answerText: answerText,
                    optionId: optionId,
                    option: nil
                )
            )
            self?.apiClient.request(
                endpoint: .castPollVote(
                    messageId: messageId,
                    pollId: pollId,
                    vote: request
                )
            ) {
                if $0.isError, let pollVote {
                    self?.database.write { session in
                        session.delete(pollVote: pollVote)
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
        completion: ((Error?) -> Void)? = nil
    ) {
        database.write { session in
            try session.removePollVote(with: voteId, pollId: pollId)
        } completion: { [weak self] error in
            if error == nil {
                self?.apiClient.request(
                    endpoint: .removePollVote(
                        messageId: messageId,
                        pollId: pollId,
                        voteId: voteId
                    )
                ) {
                    completion?($0.error)
                }
            } else {
                completion?(error)
            }
        }
    }
    
    func closePoll(
        pollId: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        let request = UpdatePollPartialRequestBody(
            pollId: pollId,
            set: ["is_closed": .bool(true)]
        )
        apiClient.request(
            endpoint: .updatePollPartial(pollId: pollId, updatePollPartialRequest: request)
        ) {
            completion?($0.error)
        }
    }
    
    func suggestPollOption(
        pollId: String,
        text: String,
        position: Int? = nil,
        custom: [String: RawJSON]? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        let request = CreatePollOptionRequestBody(
            pollId: pollId,
            text: text,
            position: position,
            custom: custom
        )
        apiClient.request(
            endpoint: .createPollOption(pollId: pollId, createPollOptionRequest: request),
            completion: {
                completion?($0.error)
            }
        )
    }
    
    func queryPollVotes(
        query: PollVoteListQuery,
        completion: ((Result<[PollVote], Error>) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .queryPollVotes(pollId: query.pollId, query: query)
        ) { [weak self] (result: Result<PollVoteListResponse, Error>) in
            switch result {
            case let .success(payload):
                var votes: [PollVote] = []
                self?.database.write({ session in
                    votes = try session.savePollVotes(payload: payload, query: query, cache: nil).map { try $0.asModel() }
                }, completion: { error in
                    if let error = error {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(votes))
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
        completion: ((Result<PollVoteListResponse, Error>) -> Void)? = nil
    ) {
        let request = QueryPollVotesRequestBody(
            pollId: pollId,
            limit: limit,
            next: next,
            prev: prev,
            sort: sort,
            filter: filter
        )
        apiClient.request(
            endpoint: .queryPollVotes(pollId: pollId, queryPollVotesRequest: request),
            completion: { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(response):
                    database.write { session in
                        for payload in response.votes {
                            if let payload {
                                try session.savePollVote(payload: payload, query: nil, cache: nil)
                            }
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
                to: query.filter?.filterHash
            )
        }
    }
}
