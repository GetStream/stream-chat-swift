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
        apiClient.request(endpoint: .createPoll(createPollRequest: request)) {
            (result: Result<PollPayloadResponse, Error>) in
            switch result {
            case let .success(response):
                completion(.success(response.poll))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
