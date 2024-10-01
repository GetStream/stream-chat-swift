In order to cast a vote for an option in a poll, you can use the `castPollVote` method:

```swift
pollController.castPollVote(
    answerText: nil,
    optionId: option.id
) { [weak self] error in
    if let error {
        // handle error
    }
}
```

You can also use this method to add a comment to a poll, without voting for an option.

```swift
pollController.castPollVote(
    answerText: "comment",
    optionId: nil
) { [weak self] error in
    if let error {
        // handle error
    }
}
```

To remove a vote, you can use the `removePollVote` method:

```swift
pollController.removePollVote(
    voteId: vote.id
) { [weak self] error in
    if let error {
        // handle error
    }
}
```

In order to suggest a new option to a poll, you can use the `suggestPollOption` method:

```swift
pollController.suggestPollOption(text: "option") { [weak self] error in
    if let error {
        // handle error
    }
}
```

To close voting for a poll, you should use the `closePoll` method:

```swift
pollController.closePoll { [weak self] error in
    if let error {
        // handle error
    }
}
```

To get the current user's votes, you can simply call `pollController.ownVotes`.