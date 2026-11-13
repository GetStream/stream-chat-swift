//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/polls-api/

import StreamChat

struct Snippets_05_07_PollsAPI {
    var channelController: ChatChannelController!
    var chatClient: ChatClient!
    var pollController: PollController!

    func pollsAtAQuickGlance() {
        // Create a poll
        channelController.createPoll(
          name: "Where should we host our next event?",
          options: [PollOption(text: "Amsterdam"), PollOption(text: "Boulder")]
        ) { result in }

        // Vote on a poll
        pollController.castPollVote(answerText: nil, optionId: "option-id") { error in }

        // Retrieve poll results
        pollController.synchronize { error in
          let poll = pollController.poll
          suppressUnusedWarning(poll)
        }
    }

    func creatingAPollAndSendingItAsPartOfAMessage() {
        channelController.createPoll(
          name: "Where should we host our next company event?",
          allowAnswers: true,
          allowUserSuggestedOptions: true,
          description: "Pick best answers",
          enforceUniqueVote: true,
          votingVisibility: .public,
          options: [
            PollOption(text: "Amsterdam, The Netherlands"),
            PollOption(text: "Boulder, CO")
          ]) { result in
            // …
          }
    }

    func pollOptions() {
        channelController.createPoll(
          name: "Where should we host our next company event?",
          options: [
            PollOption(
              text: "Amsterdam, The Netherlands",
              extraData: ["venue capacity": .number(300)]
            ),
            PollOption(
              text: "Boulder, CO",
              extraData: ["venue capacity": .number(1000)]
            )
          ]
        ) { result in
            // …
          }
    }

    func sendVoteOnOption() {
        let pollController = chatClient.pollController(
          messageId: "message-id",
          pollId: "poll-id"
        )
        pollController.castPollVote(
          answerText: nil,
          optionId: "option-id") { error in
            // ...
          }
    }

    func sendAnAnswer() {
        let pollController = chatClient.pollController(
          messageId: "message-id",
          pollId: "poll-id"
        )
        pollController.castPollVote(
          answerText: "This is my answer text",
          optionId: nil) { error in
            // ...
          }
    }

    func removingAVote() {
        pollController.removePollVote(voteId: "vote-id") { error in
          // …
        }
    }

    func closingAPoll() {
        pollController.closePoll { error in
          // …
        }
    }

    func retrievingAPoll() {
        let pollController = chatClient.pollController(
          messageId: "message-id",
          pollId: "poll-id"
        )
        pollController.synchronize { error in
          let poll = pollController.poll
          suppressUnusedWarning(poll)
        }
    }

    func deletingAPoll() {
        let channelController = chatClient.channelController(
          for: ChannelId(type: .messaging, id: "general")
        )
        channelController.deletePoll(pollId: "poll-id") { error in
          // ...
        }
    }

    func addPollOption() {
        let pollController = chatClient.pollController(
          messageId: "message-id",
          pollId: "poll-id"
        )
        pollController.suggestPollOption(text: "Another option") { error in
          // ...
        }
    }

    func queryingVotes() {
        let query = PollVoteListQuery(
          pollId: "poll-id",
          optionId: "option-id"
        )
        let voteListController = chatClient.pollVoteListController(query: query)
        voteListController.synchronize { error in
          let votes = voteListController.votes
          suppressUnusedWarning(votes)
        }
    }
}
