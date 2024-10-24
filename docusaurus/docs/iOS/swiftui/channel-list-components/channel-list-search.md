---
title: Channel List Search
---

### Basic Usage

The channel list component shows a search bar at the top that lets you search through messages or channels depending on the `searchType` provided when creating the `ChatChannelListView` component. By default, the search type is set to `.messages`, which means that the search will be performed on messages inside the channels and threads.

If you want to change the search type to `.channels`, you can do so by setting the `searchType` parameter when creating the `ChatChannelListView` component:

```swift
ChatChannelListView(
    viewFactory: CustomAppFactory.shared,
    searchType: .channels
)
```

:::note
The `searchType` parameter is only available on the SwiftUI SDK since version [4.66.0](https://github.com/GetStream/stream-chat-swiftui/releases/tag/4.66.0).
:::

### Navigation

When a user taps on a search result, the corresponding channel is opened, automatically scrolling to the searched message or channel depending on the `searchType`.

The SwiftUI components can also scroll to a message that is not available in the local database at that moment. In those cases, the messages around that message are also loaded. The scrolling in these cases can happen in both directions - up (for loading older messages) and down (for loading newer messages).

You can also search for messages that are part of message threads. In those cases, first the channel is opened, and then the corresponding message thread is shown, scrolling to the searched message.

### Search Bar

In order to replace the search bar with your own (or completely remove it by returning an EmptyView), you need to implement the `makeChannelListTopView` method:

```swift
func makeChannelListTopView(
    searchText: Binding<String>
) -> some View {
    SearchBar(text: searchText)
}
```

In this method, a binding of the search text is provided, in case you want to implement your custom search bar.

### Message Search Controller

Under the hood, the channel list search uses the `MessageSearchController` when the `searchType` is set to `.messages`, so that you can also use it to provide search in your custom UI components.

Here's an example how to search for a particular search text:

```swift
let messageSearchController = chatClient.messageSearchController()
let query = MessageSearchQuery(
    channelFilter: .containMembers(userIds: [userId]),
    messageFilter: .autocomplete(.text, text: searchText)
)
messageSearchController?.search(query: query, completion: { [weak self] _ in
    self?.updateSearchResults()
})
```

In order to perform search, you need to create a `MessageSearchQuery`. The query consists of `channelFilter` and `messageFilter`.

The `channelFilter` defines which channels should be included in the filter. In the query above, we are including all channels that the current user is part of, by using the `containMembers` filter, that contains the current user id.

The message filter defines which messages should be returned in the search query. In this case, we are using the `autocomplete` filter, with a search text taken from the user's input.

For the different message search options, please check this [page](https://getstream.io/chat/docs/ios-swift/search/?language=swift).