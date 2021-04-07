---
title: Working with Channel List
---

## Understanding `ChannelListQuery`

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
For more information about `team`, please refer to our [Multi-Tenancy Guide](multi-tenancy).

For more information about filters, please refer to our [Filter & Query Guide](filter-query-guide).

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

## Displaying the list of Channels

Displaying the list of channels consists of creating the controller for the list you want to display, passing this controller to a `ChatChannelListVC` instance, and displaying the view controller. To demonstrate:

<img align="right" src="../img/channel-list.png" width="20%" />

```swift
// Create the query for the channel list we desire
let query = ChannelListQuery(filter: .containMembers(userIds: [client.currentUserId!]))
// Create the ChannelListController for the query
let controller = chatClient.channelListController(query: query)
// Create the ChatChannelListVC instance
let channelListVC = ChatChannelListVC()
// Pass the controller to the VC
channelListVC.controller = controller
// Display the VC
present(channelListVC, animated: true)
```
It's that easy. `ChatChannelListVC` internally handles all parameters, sorting, pagination and updating the list in itself. The rest of this guide will explain how to work with controller, for a guide on `ChatChannelListVC`, please refer to [ChatChannelListVC Component Overview](404)

## Getting the list of Channels for a User

If you'd like to have your own UI component, for access the list of channels for any other purpose, you can do so as shown here:
```swift
// Create the query for the channel list we desire
let query = ChannelListQuery(filter: .containMembers(userIds: [client.currentUserId!]))
// Create the ChannelListController for the query
let controller = chatClient.channelListController(query: query)
// Access `channels` property directly
let firstChannel = controller.channels[0]
print(firstChannel.name)
```
Accessing the `channels` property of a controller starts the initial database fetch automatically, and will return whatever data you have locally cached.

### Importance of `synchronize`

As stated above, plainly accessing `channels` property will only make locally available data visible. If your client is not up-to-date with backend, or it never cached any data, you need to call `synchronize` to make local client sync with backend.
After you call `synchronize`, your `channels` property will be updated and you'll have the latest channels.
```swift
// Create the query for the channel list we desire
let query = ChannelListQuery(filter: .containMembers(userIds: [client.currentUserId!]))
// Create the ChannelListController for the query
let controller = chatClient.channelListController(query: query)
// Call synchronize on controller
controller.synchronize { error in
    // Controller reports error if any happened
    if let error = error {
        // Handle error here
        print("Error happened during synchronize: \(error)")
        return
    }
    // At this point, you're safe to access newly fetched channels
    // Access `channels` property directly
    let firstChannel = controller.channels[0]
    print(firstChannel.name)
}
```

### Observing changes to Channel List

Accessing `channels` property of the controller is not ideal, so in many cases you'd require a way to observe changes to this property. There are 2 most common ways of doing so: UIKit Delegates and SwiftUI/Combine publishers.

#### UIKit Delegates

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

#### SwiftUI/Combine


## Paginating Channel List

## Marking all Channels as Read




- Creating a channel
    - Why/When do we need `synchronize`
- Listing channels → Displays ChannelListVC and links
    - Using different filters to display different lists of channels
    - Getting next page of channels
- Observing changes to channels
- Marking all channels as read

