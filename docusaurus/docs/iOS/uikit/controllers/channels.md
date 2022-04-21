---
title: Channel Controllers
---

## ChannelListController

`ChatChannelListController` allows you to observe a list of chat channels based on the provided query and to paginate channels.

### ChannelList Delegate

Classes that conform to the `ChatChannelListControllerDelegate` protocol will receive changes to the queried list of channels.

```swift
func controller(
    _ controller: ChatChannelListController,
    didChangeChannels changes: [ListChange<ChatChannel>]
)
```

### Having more than one ChannelListController active at the same time

When having 2 active controllers at the same time, you need to initialize them by passing a `filter` block. This will make sure events are routed to the right list.

```
client.channelListController(query: query, filter: { channel in
    // Your filtering logic
    return true
})
```

It is expected that the logic on the `filter` block matches the one in `query.filter`.

:::note
Given the nature of `Filter`, having generic logic capable of using `query.filter` at runtime to determine if a ChatChannel meets the criteria is extremely expensive and complex. Instead, having a block that only checks for the particular needs of the use case is much cheaper.
:::

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
