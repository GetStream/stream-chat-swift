---
title: Channel List
---

import SingletonNote from '../../common-content/chat-client.md'
import ComponentsNote from '../../common-content/components-note.md'
import Properties from '../../common-content/reference-docs/stream-chat-ui/chat-channel-list/chat-channel-list-vc-properties.md'

This component is used to display a list of channels. Channels are fetched from the API and kept in sync automatically. Behind the scenes this component uses the `Query Channels` API endpoint and Websocket events.

## Basic Usage

You can show the list of channels for the current user by adding the `ChatChannelListVC` to your application.

```swift
class ViewController: ChatChannelListVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /// the query used to retrieve channels
        let query = ChannelListQuery.init(filter: .containMembers(userIds: [ChatClient.shared.currentUserId!]))
        
        /// create a controller and assign it to this view controller
        self.controller = ChatClient.shared.channelListController(query: query)
    }
}
```

<SingletonNote />

If you have a navigation controller setup the SDK will navigate from the channel list to the channel view controller when the user taps on a channel. In the example above we are showing the channels where the current user is a member, you can change the query to fit your application needs.

## UI Customization

You can customize how channels are rendered in the list by replacing the [`ChannelListItemView`](../../views/channel-list-item-view) component with your own. Like every component from this library, this component will also follow the [theming](../theming.md) of your application.

### Channel Header

The header of the channel can be configured the same way you would configure it on a `UIViewController` object.

```swift
class ViewController: ChatChannelListVC {
    /// ...

    override open func setUpAppearance() {
        super.setUpAppearance()
        title = "Chats"
    }

    /// ...
}
```

## Navigation

This component uses the [`ChannelListRouter`](../../common-content/reference-docs/stream-chat-ui/navigation/chat-channel-list-router.md) navigation component, you can customize this by providing your own.

```swift
Components.channelListRouter = CustomChannelListRouter.self
```

<ComponentsNote />

## Channel List Controller

The channel list component uses the `ChannelListController` to fetch the list of channels matching your query and to stay up-to-date with all changes. In the example above you can see that we are passing a `ChannelListQuery` object to create the controller. Stream Chat APIs allow you to list channels based on your own query and sort.

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

## Marking all Channels as Read

When you're displaying, or loading a set of channels, you may want to mark all the channels as read. For this, `ChannelListController` has `markAllRead` function:
```swift
controller.markAllRead()
```
This function will reset the unread count for all the channels the controller paginates.

## Properties

<Properties />
