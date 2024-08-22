//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools

struct PollMockFactory {
    var currentUser: ChatUser

    init(currentUser: ChatUser) {
        self.currentUser = currentUser
    }

    func makePoll(
        isClosed: Bool,
        enforceUniqueVote: Bool = false,
        maxVotesAllowed: Int? = nil,
        createdBy: ChatUser? = nil
    ) -> Poll {
        Poll.mock(
            enforceUniqueVote: enforceUniqueVote,
            name: "The Best Football Player of All Time A.K.A. The Goat",
            voteCount: 6,
            voteCountsByOption: [
                "ronaldo": 3,
                "eusebio": 2,
                "pele": 1,
                "maradona": 0,
                "messi": 0
            ],
            isClosed: isClosed,
            maxVotesAllowed: maxVotesAllowed,
            createdBy: createdBy ?? currentUser,
            options: [
                .init(id: "messi", text: "Messi"),
                .init(id: "ronaldo", text: "Cristiano Ronaldo dos Santos Aveiro", latestVotes: [
                    .mock(createdAt: "2024-07-26T12:25:07.25741Z".toDate(), user: currentUser),
                    .mock(
                        createdAt: "2024-06-20T16:25:07.25741Z".toDate(),
                        user: .mock(id: .unique, name: "Pep Guardiola")
                    ),
                    .mock(
                        createdAt: "2024-04-20T07:25:07.25741Z".toDate(),
                        user: .mock(id: .unique, name: "Rui Costa")
                    )
                ]),
                .init(id: "pele", text: "Pele", latestVotes: [
                    .mock(
                        createdAt: "2024-03-26T12:25:07.25741Z".toDate(),
                        user: .mock(id: .unique, name: "Zico")
                    )
                ]),
                .init(id: "maradona", text: "Maradona"),
                .init(id: "eusebio", text: "Eusebio", latestVotes: [
                    .mock(createdAt: "2024-05-26T12:25:07.25741Z".toDate(), user: currentUser),
                    .mock(
                        createdAt: "2024-03-26T15:25:07.25741Z".toDate(),
                        user: .mock(id: .unique, name: "Di Maria")
                    )
                ])
            ],
            ownVotes: [
                .mock(optionId: "ronaldo"),
                .mock(optionId: "eusebio")
            ]
        )
    }
}
