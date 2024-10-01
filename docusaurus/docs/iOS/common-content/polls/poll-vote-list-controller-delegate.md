To listen to updates of the `PollVoteListController` you should implement the `PollVoteListControllerDelegate` method:

```swift
/// The controller changed the list of observed votes.
///
/// - Parameters:
///   - controller: The controller emitting the change callback.
///   - changes: The change to the list of votes.
func controller(
    _ controller: PollVoteListController,
    didChangeVotes changes: [ListChange<PollVote>]
)
```