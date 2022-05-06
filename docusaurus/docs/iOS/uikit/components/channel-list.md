---
title: Channel List
---

import SingletonNote from '../../common-content/chat-client.md'
import ComponentsNote from '../../common-content/components-note.md'
import Properties from '../../common-content/reference-docs/stream-chat-ui/chat-channel-list/chat-channel-list-vc-properties.md'

The `ChatChannelListVC` is the UI component used to display a list of channels matching the given query.

:::note
The Channel List screen is backed by the low-level `ChatChannelListController` component which fetches channels from the API and keeps the list in sync with the remote.
Read more about about channel list query and how `ChatChannelListController` works [here](../controllers/channels.md).
:::

## Basic Usage

The first step to show the channel list screen in your app is to create `ChatChannelListVC` instance:
```swift
// Create `ChatChannelController` with the given query
let controller = ChatClient.shared.channelListController(query: ..., filter: ...)

// Create a view controller backed by the low-level controller
let channelListVC = ChatChannelListVC.make(with: controller)
```

When the `ChatChannelListVC` instance is created, there are multiple ways of showing it:
1. modally
1. inside existed `UINavigationController`
1. as a tab inside `UITabBarController`
1. as a child controller

To present the channel list modally:
```swift
let navigationVC = UINavigationController(rootViewController: channelListVC)

present(navigationVC, animated: true)
```

To push the channel list to existed navigation controller:
```swift
navigationController?.push(channelListVC, animated: true)
```

To show the channel list as a tab:
```swift
let navigationVC = UINavigationController(rootViewController: channelListVC)

let tabBatVC = UITabBarController()
tabBatVC.viewControllers = [..., navigationVC]
```

To show the channel list as a child:
```swift
class ParentVC: UIViewController {
    let containerView: UIView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationVC = UINavigationController(rootViewController: channelListVC)
        addChild(navigationVC)
        navigationVC.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(navigationVC.view)
        NSLayoutConstraint.activate([
            navigationVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            navigationVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            navigationVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            navigationVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        navigationVC.didMove(toParent: self)
    }
}
```

:::note
In all the cases but the push to the existing navigation controller, the channel list is wrapped by `UINavigationController` before presenting to get the `channel list -> channel` navigation out of the box.
:::

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
