---
title: Channel Controllers
---

import SingletonNote from '../../common-content/chat-client.md'

## ChannelListController

`ChatChannelListController` is the component responsible for managing the list of channels matching the given query. The main responsibilities are:
- exposing the list of channels matching the query
- allowing to paginate the channel list (initially, only the 1st page of channels is fetched)
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

### 2. Create a controller

The controller can be created using `ChatClient`:
```swift
let controller = ChatClient.shared.channelListController(query: query, filter: { channel in
    // the filtering logic goes here.
    return true
})
```

The `filter` closure is needed to dynamically link/unlink channels to the list during the controller's lifecycle to keep the list in sync with the remote:

When `filter` returns `true`, the new/updated channel is linked/stays linked to the channel list

When `filter` returns `false`, the new/updated channel is not linked/is unlinked from the channel list.

:::note
It is expected that the logic on the `filter` closure matches the one in `query.filter`.
:::

:::note
Given the complex nature of `Filter`, having generic logic capable of using `query.filter` at runtime to determine if a channel meets the criteria is extremely expensive and complex. Instead, having a block that checks for the particular needs of the use case is much cheaper.
:::

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

Calling `synchronize` on the controller is the commonly used approach in `StreamChat` SDK (read more [here](../../guides/importance-of-synchronize.md)).

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

### Example: Typing Indicator

Let's build a simple UIView that shows the current unread count for the current user.

```swift
class TypingIndicatorView: UIView, ChatChannelControllerDelegate {
    var labelView: UILabel = {
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(labelView)

        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: topAnchor),
            labelView.bottomAnchor.constraint(equalTo: bottomAnchor),
            labelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func channelController(_ channelController: ChatChannelController, didChangeTypingUsers typingUsers: Set<ChatUser>) {
        let otherUsersTyping = typingUsers.filter({ $0.id != channelController.client.currentUserId })
        
        guard let typingUser = otherUsersTyping.first else {
            labelView.text = ""
            return
        }
        
        labelView.text = "\(typingUser.name ?? typingUser.id) is typing ..."
    }
}

class ViewController: UIViewController {
    var controller: ChatChannelController!

    var typingIndicatorView: TypingIndicatorView = {
        var view = TypingIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let cid = ChannelId.init(type:.messaging, id:"the-id-of-the-channel")
        controller = ChatClient.shared.channelController(for: cid)
        controller.synchronize()

        controller.delegate = typingIndicatorView
        navigationItem.titleView = typingIndicatorView
    }
}
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

### Example: Listing Members

This example uses the `ChatChannelMemberListController` to fetch all members on the channel `messaging:123` and sets a view as its delegate.

```swift
class MembersSearchResultsView: UIView, ChatChannelMemberListControllerDelegate {
    var labelView: UILabel = {
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(labelView)

        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: topAnchor),
            labelView.bottomAnchor.constraint(equalTo: bottomAnchor),
            labelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func memberListController(_ controller: ChatChannelMemberListController, didChangeMembers changes: [ListChange<ChatChannelMember>]) {
        let membersStr = controller.members.map { $0.name ?? $0.id }.joined(separator: ", ")
        labelView.text = membersStr

        print("\(changes.count) members changed (added/inserted/deleted)")
    }
}

class ViewController: UIViewController {
    var controller: ChatChannelMemberListController!

    var membersSearchResultsView: MembersSearchResultsView = {
        var view = MembersSearchResultsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cid = ChannelId.init(type:.messaging, id:"123")
        let query = ChannelMemberListQuery.init(cid: cid)
        
        controller = ChatClient.shared.memberListController(query: query)
        controller.delegate = membersSearchResultsView

        controller.synchronize {error in
            if error != nil {
                log.assertionFailure(error!)
            }
        }

        navigationItem.titleView = membersSearchResultsView
    }
}
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
