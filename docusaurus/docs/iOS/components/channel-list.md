---
title: Channel List
---

import SingletonNote from '../common-content/chat-client.md'
import ComponentsNote from '../common-content/components-note.md'
import Properties from '../common-content/reference-docs/stream-chat-ui/chat-channel-list/chat-channel-list-vc-properties.md'

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

You can customize how channels are rendered in the list by replacing the [`ChannelListItemView`](channel-list-item-view.md) component with your own. Like every component from this library, this component will also follow the [theming](../customization/theming.md) of your application.

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

This component uses the [`ChannelListRouter`](../common-content/reference-docs/stream-chat-ui/navigation/chat-channel-list-router.md) navigation component, you can customize this by providing your own.

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
        filter: Filter<_ChannelListFilterScope<ExtraData>>,
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

## Observing changes to Channel List

Accessing `channels` property of the controller is not ideal, so in many cases you'd require a way to observe changes to this property. There are 3 most common ways of doing so: UIKit Delegates, Combine publishers and SwiftUI wrappers.

### UIKit Delegates

`ChatChannelListController` has `ChatChannelListControllerDelegate` with `didChangeChannels` function:
```swift
func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    )
```
Whenever the `channels` property of the controller changes, this delegate function will be called. So, our example above becomes:
```swift
class ChannelListViewController: UIViewController {

    let channelListController = chatClient.channelListController(
       query: ChannelListQuery(filter: .containMembers(userIds: [chatClient.currentUserId]))
    )

    override func viewDidLoad() {
       super.viewDidLoad()
       channelListController.delegate = self

       // update your UI with the cached channels first, for example by calling reloadData() on UITableView
       let locallyAvailableChannels = channelListController.channels

       // call `synchronize()` to update the locally cached data. the updates will be delivered using delegate methods
       channelListController.synchronize()
    }
}

extension ChannelListViewController: ChatChannelListControllerDelegate { 
    func controller(_ controller: ChatChannelListController, didChangeChannels changes: [ListChange<Channel>]) {
        // The list of channels has changed. You can for example animate the changes:

        tableView.beginUpdates()        
        for change in changes {
            switch change {
            case let .insert(_, index: index):
                tableView.insertRows(at: [index], with: .automatic)
            // etc ...
            }
        }        
        tableView.endUpdates()
    }
}
```

Additionally, as with all StreamChat Controllers, `ChannelListController` has `state` and a delegate function to observe it's `state`:
```swift
func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
You can use this delegate function to show any error states you might see. For more information, see [DataController Overview](404).

### Combine publishers

`ChannelListController` has publishers for its `channels` property so it's observable, like so:
```swift
class ChannelsViewController: UIViewController {

    let channelListController = chatClient.channelListController(
       query: ChannelListQuery(filter: .containMembers(userIds: [chatClient.currentUserId]))
    )

    private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
       super.viewDidLoad()

       // update your UI with the cached channels first, for example by calling reloadData() on UITableView
       let locallyAvailableChannels = channelListController.channels

       // Observe changes to the list from the publishers
        channelListController
             .channelsChangesPublisher
             .receive(on: RunLoop.main)
             .sink { [weak self] changes in
                // animate the changes to the channel list
             }
             .store(in: &cancellables)

       // call `synchronize()` to update the locally cached data. the updates will be delivered using channelsChangesPublisher
       channelListController.synchronize()
    }
}
```

### SwiftUI Wrappers

`ChannelListController` is fully compatible with SwiftUI.
```swift
// View definition

struct ChannelListView: View {
    @ObservedObject var channelList: ChatChannelListController.ObservableObject

    init(channelListController: ChatChannelListController) {
        self.channelList = channelListController.observableObject
    }

    var body: some View {
        VStack {
            List(channelList.channels, id: \.self) { channel in
                Text(channel.name)
            }
        }
        .navigationBarTitle("Channels")
        .onAppear { 
            // call `synchronize()` to update the locally cached data.
            channelList.controller.synchronize() 
        }
    }
}

// Usage

let channelListController = chatClient.channelListController(
    query: ChannelListQuery(filter: .containMembers(userIds: [chatClient.currentUserId]))
)

let view = ChannelListView(channelListController: channelListController)
```

## Marking all Channels as Read

When you're displaying, or loading a set of channels, you may want to mark all the channels as read. For this, `ChannelListController` has `markAllRead` function:
```swift
controller.markAllRead()
```
This function will reset the unread count for all the channels the controller paginates.

## Properties

<Properties />
