The `Poll` model contains the data needed to present a poll:

- `allowAnswers: Bool` - Indicates whether the poll allows answers.
- `allowUserSuggestedOptions: Bool` - Indicates whether the poll allows user-suggested options.
- `answersCount: Int` - The count of answers received for the poll.
- `createdAt: Date` - The date and time when the poll was created.
- `pollDescription: String?` - A brief description of the poll. This property is optional and may be `nil`.
- `enforceUniqueVote: Bool` - Indicates whether the poll enforces unique votes.
- `id: String` - The unique identifier of the poll.
- `name: String` - The name of the poll.
- `updatedAt: Date?` - The date and time when the poll was last updated. This property is optional and may be `nil`.
- `voteCount: Int` - The count of votes received for the poll.
- `extraData: [String: RawJSON]` - A dictionary containing custom fields associated with the poll.
- `voteCountsByOption: [String: Int]?` - A dictionary mapping option IDs to the count of votes each option has received. This property is optional and may be `nil`.
- `isClosed: Bool` - Indicates whether the poll is closed.
- `maxVotesAllowed: Int?` - The maximum number of votes allowed per user. This property is optional and may be `nil`.
- `votingVisibility: VotingVisibility?` - Represents the visibility of the voting process. This property is optional and may be `nil`.
- `createdBy: ChatUser?` - The user who created the poll. This property is optional and may be `nil`.
- `latestAnswers: [PollVote]` - A list of the latest answers received for the poll.
- `options: [PollOption]` - An array of options available in the poll.
- `latestVotesByOption: [PollOption]` - A list of the latest votes received for each option in the poll.

In order to create a poll in your custom UI components, you need to use the `ChatChannelController` method `createPoll`:

```swift
chatController.createPoll(
    name: question.trimmed,
    allowAnswers: allowComments,
    allowUserSuggestedOptions: suggestAnOption,
    enforceUniqueVote: !multipleAnswers,
    maxVotesAllowed: maxVotesAllowed,
    votingVisibility: anonymousPoll ? .anonymous : .public,
    options: pollOptions
) { [weak self] result in
    switch result {
    case let .success(messageId):
        log.debug("Created poll in message with id \(messageId)")
        completion()
    case let .failure(error):
        log.error("Error creating a poll: \(error.localizedDescription)")
        self?.errorShown = true
    }
}
```

To perform operations on a poll (for example, adding and removing votes), you need a `PollController`.

Poll controllers can be created with the `ChatClient`, by specifying the message id and the poll id:

```swift
let pollController = chatClient.pollController(
    messageId: message.id,
    pollId: poll.id
)
```