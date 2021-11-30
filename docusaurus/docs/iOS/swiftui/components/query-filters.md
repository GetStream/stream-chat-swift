---
title: Channels filters and sorting
---

## Filters and Sorting

The `ChatChannelListView` component uses the `ChannelListController` to fetch the list of channels matching your query and to stay up-to-date with all changes. The SwiftUI SDK allows you to list channels based on your own query and sorting criteria.

By default, the SDK creates a `ChannelListController` which loads all the channels for the current user, without any additional filtering or sorting criteria.

You can create your own `ChannelListController` and inject it in the `ChatChannelListView`. Here's an example how to do that.

```swift
var body: some Scene {
        WindowGroup {
            ChatChannelListView(
                viewFactory: CustomFactory.shared,
                channelListController: customChannelListController
            )
        }
    }
    
    private var customChannelListController: ChatChannelListController {
        let controller = chatClient.channelListController(
            query: .init(
                filter: .and([.equal(.type, to: .messaging), .containMembers(userIds: [chatClient.currentUserId!])]),
                sort: [.init(key: .lastMessageAt, isAscending: true)],
                pageSize: 10
            )
        )
        return controller
    }
```

In the example, we're changing the sorting in the opposite order - getting the oldest messages first.

## Channel List Query

The `ChannelListQuery` is the structure used for specifiying the query parameters for fetching the list of channels from Stream backend.
It has 4 parameters in it's `init`:

```swift
public init(
    filter: Filter<ChannelListFilterScope>,
    sort: [Sorting<ChannelListSortingKey>] = [],
    pageSize: Int = .channelsPageSize,
    messagesLimit: Int = .messagesPageSize
)
```

Let's dive deep into each one.

### Filter

Filter is the main parameter for a query. You can define different filters to fetch different sets of channels for a user.
Examples of some most commonly used filters:
```swift
// Assume we've already created and configured our ChatClient

// Filter for channels where our user is a member
let filter = Filter<ChannelListFilterScope>.containMembers(userIds: [client.currentUserId!])

// Filter for channels where the name starts with "Group"
let filter = Filter<ChannelListFilterScope>.autocomplete(.name, text: "Group")

// Compound Filter for channels where team is read and our user is a member
let filter = Filter<ChannelListFilterScope>.and([.equal(.team, to: "read"),
                                                 .containMembers(userIds: [client.currentUserId!])])
```

### Sorting

Sorting parameter is used to sort the list of channels returned. By default, Channel List will be sorted by their last message date (or channel creation date, if the channel is empty).
Most commonly, you don't need to specify any sorting, StreamChat SDK handles this. If you'd like, you can create custom sortings, such as:
```swift
// Sorting for always showing most crowded channels first
let sorting: [Sorting<ChannelListSortingKey>] = [.init(key: .memberCount, isAscending: true),
                                                 .init(key: .lastMessageAt, isAscending: true)]
```

### PageSize

Page size is used to specify how many channels the initial page will show. You can specify an integer value for advanced usecases. Most commonly, you don't need to touch this.

### Message Limit

`messagesLimit` is used to specify how many messages the initial fetch will return.
