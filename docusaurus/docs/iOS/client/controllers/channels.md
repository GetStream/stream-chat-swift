---
title: Channels State and Filtering
---

import SingletonNote from '../../common-content/chat-client.md'

## ChannelListController

`ChatChannelListController` is the component responsible for managing the list of channels matching the given query. The main responsibilities are:
- exposing the list of channels matching the query
- allowing to paginate the channel list (initially, only the first page of channels is fetched)
- keeping the list of channels in sync with the remote by dynamically linking/unlinking channels that start/stop matching the query

Here is the code snippet showing how to instantiate `ChatChannelListController` showing the channels the current user is a member of:
```swift
// 1. Create a query matching channels where members contain the current user  
let query = ChannelListQuery(filter: .containMembers(userIds: [currentUserId]))

// 2. Create a controller
let controller = ChatClient.shared.channelListController(query: query, filter: { channel in
    return channel.membership != nil
})

// 3. Set the delegate
controller.delegate = delegate

// 4. Synchronize a controller
controller.synchronize { error in /* handle error */ }
```

Let's go through step by step.

<SingletonNote />

### 1. Create a query

The channel list query is described by `ChannelListQuery` type. The main parts of the query are filter and sorting options.

The `query.filter` determines a set of conditions the channel should satisfy to match the query. It can contains conditions for **built-in** channel fields:
```swift
let filter1: Filter<ChannelListFilterScope> = .equal(.type, to: .messaging)
```
as well as conditions for **custom** fields:
```swift
let filter2: Filter<ChannelListFilterScope> = .equal("state", to: "LA")
```
Primitive filters can be **combined** using `and/or/nor` operators which allow getting a filter of any complexity:
```swift
let compoundFilter: Filter<ChannelListFilterScope> = .and([
    filter1,
    filter2
])
```

The `query.sort` is an array of sorting options. Sorting options are applied based on their order in the array so the first option has the highest impact while the others are used mainly as a tiebreakers. By default, the channel list is sorted by `updated_at`.

#### Sorting with custom / extra data:

When sorting using a property that is not by default available in `ChannelListSortingKey`, you can create a custom one as such:

```swift
let key = ChannelListSortingKey.custom(keyPath: \.myCustomValue, key: "custom_score.value")
let customValueSorting = Sorting<ChannelListSortingKey>(key: key, isAscending: false)
let query = ChannelListQuery(filter: filter, sort: [customValueSorting])

```

In order for the above to work, you need to create a computed property to access the custom value that you want to use to sort:
```swift
extension ChatChannel {
    var myCustomValue: Double {
        return extraData["custom_score"]?["value"]?.numberValue ?? 0
    }
}

```

### 2. Create a controller

The simplest way to create a controller is by using the method `channelListController(query:)` on your `ChatClient`.
```swift
let controller = ChatClient.shared.channelListController(query: query)
```
By default, the SDK will automatically handle filtering the channels as they get created. Whenever there is a web socket event that a channel has been created, the SDK will only insert it in the channel list if it matches the query.

:::note
In cases, though, where the query provided contains extra data or custom filters, **the SDK may not be able to automatically match the filter query**. In this case, you will need to provide a filtering closure.
:::

#### Filtering with extra data

Currently the SDK doesn't support filtering on values in the extra data dictionary. In this case, we will need to evaluate manually the part of the query that checks the dictionary. In the code below you can see an example:
:::note
Notice how we are only evaluating manually, the part of the query regarding the `myCustomBooleanKey`. The rest of the query has been already evaluated by the SDK and the results have been partially filtered.
:::
```swift
let controller = ChatClient.shared.channelListController(query: .and([
    .containMembers(userIds: [currentUserId]),
    .equal(.type, to: .messaging),
    .equals("myCustomBooleanKey", value: true)
]), filter: { channel in
    // The channel is guaranteed to:
    // 1. contain a member with id the currentUserId
    // 2. have type == `.messaging` 
    // We are filtering for channels that a value exists for the extraData 
    // key `myCustomBooleanKey` and this value is `true`
    return channel.extraData["myCustomBooleanKey"]?.boolValue == true
})
```
#### Manual Filtering

First we need to disable the Channel auto-filtering. We can do that by turning the `isChannelAutomaticFilteringEnabled` in your `ChatClient` configuration, to `false`.
```swift
extension ChatClient {
    static let shared: ChatClient = {
        // You can grab your API Key from https://getstream.io/dashboard/
        var config = ChatClientConfig(apiKeyString: "<# Your API Key Here #>")
        config.isChannelAutomaticFilteringEnabled = false
        // Create an instance of the `ChatClient` with the given config
        let client = ChatClient(config: config)
        return client
    }()
}
```
Then, we will need to provide to our ChannelController a filtering closure. We can achieve this with the code below:
```swift
let controller = ChatClient.shared.channelListController(query: .and([
    .containMembers(userIds: [currentUserId]),
    .equal(.type, to: .messaging),
    .equals("myCustomBooleanKey", value: true)
]), filter: { channel in
    // As we have disabled the auto-filtering, the SDK will not try to match
    // the channels in the filter and instead will forward them to the 
    // filter closure where we are expected to apply our custom 
    // filtering logic.
    // 
    // In this case, we need to evaluate manually all parts of the filter.
    return channel.members.map(\user.id).contains(currentUserId) 
        && channel.type == .messaging,
        && channel.extraData["myCustomBooleanKey"]?.boolValue == true
})
```

### 3. Set the delegate

An instance of the type conforming to `ChatChannelListControllerDelegate` protocol can be assigned as controller's delegate:
```swift
controller.delegate = delegate
```

:::note
An integrator should make sure to keep a strong reference to the `delegate` passed to the controller. Otherwise, the delegate object will get deallocated since the controller references it **weakly**.
:::

### 4. Synchronize controller

The `synchronize` should be called on the controller to:
- fetch the first page of channels matching the query
- subscribe to events for those channels
- start observing data changes

```swift
controller.synchronize { error in 
    /* handle error */
}
```

Calling `synchronize` on the controller is the commonly used approach in `StreamChat` SDK (read more [here](../../client/importance-of-synchronize.md)).

## ChannelController

`ChatChannelController` allows you to observe and mutate data for one channel.

### Channel Delegate

Classes that conform to the `ChatChannelControllerDelegate` protocol will receive changes to channel data, members, messages and currently typing users.

```swift
func channelController(
    _ channelController: ChatChannelController,
    didUpdateChannel channel: EntityChange<ChatChannel>
) {}

func channelController(
    _ channelController: ChatChannelController,
    didUpdateMessages changes: [ListChange<ChatMessage>]
) {}

func channelController(
    _ channelController: ChatChannelController,
    didChangeTypingUsers typingUsers: Set<ChatUser>
) {}

func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent: MemberEvent) {}
```

## ChannelMemberListController

`ChatChannelMemberListController` allows you to observe and mutate data and observing changes for a list of channel members based on the provided query.

### ChannelMemberList Delegate

Classes that conform to the `ChatChannelMemberListControllerDelegate` protocol will data and changes for a list of members queried by the controller.

```swift
func memberListController(
    _ controller: ChatChannelMemberListController,
    didChangeMembers changes: [ListChange<ChatChannelMember>]
)
```

## ChannelMemberController

`ChatChannelMemberController` allows you to observe and mutate data and observing changes of a specific chat member.

### ChannelMember Delegate

Classes that conform to the `ChatChannelMemberControllerDelegate` protocol will receive changes to channel data, members, messages and typing users.

```swift
func memberController(
    _ controller: ChatChannelMemberController,
    didUpdateMember change: EntityChange<ChatChannelMember>
)
```
