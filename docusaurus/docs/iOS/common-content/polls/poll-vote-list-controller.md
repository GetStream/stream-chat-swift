In order to paginate through votes (and answers), you should create a `PollVoteListController`, through the `ChatClient` instance.

For example, if you want to paginate through all the votes for a given option, you can use the following code:

```swift
let query = PollVoteListQuery(
    pollId: poll.id, 
    optionId: option.id
)
let controller = chatClient.pollVoteListController(query: query)
```

To paginate through all the comments (answers) in a poll, you can use the following query:

```swift
let query = PollVoteListQuery(
    pollId: poll.id,
    filter: .equal(.isAnswer, to: true)
)
let commentsController = chatClient.pollVoteListController(query: query)
```