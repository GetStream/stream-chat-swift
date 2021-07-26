---
title: Channel Controllers
---

## ChannelListController

`ChatChannelListController` allows you to observe a list of chat channels based on the provided query and to paginate channels.

### Publishers in `ChannelListController`

To receive a queried list of channels, you can use the `channelsChangesPublisher` provided by the `ChatChannelListController`

```swift
 channelListController
            .channelsChangesPublisher
            .sink(receiveValue: { 
                // process the channel changes here
            })
            .store(in: &cancellables)
```

## ChannelController

`ChatChannelController` allows you to observe and mutate data for one channel.

### Publishers in `ChannelController`

The `channelChangePublisher` will emit a new value every time the channel changes.

```swift
channelController
            .channelChangePublisher
            .sink(receiveValue: { 
                // Process the updated channel data here
            })
            .store(in: &cancellables)
```

The `messagesChangesPublisher` will emit a new value every time the list of the messages matching the query changes.

```swift
channelController
            .messagesChangesPublisher
            .sink(receiveValue: { 
                //Process the messages changes here 
            })
            .store(in: &cancellables)
```

The `memberEventPublisher` will emit a new value every time a member event is received.

```swift
channelController
            .memberEventPublisher
            .sink(receiveValue: { 
                // Process the member events here
            })
            .store(in: &cancellables)
```

The `typingUsersPublisher` will emit a new value every time typing users change.

```swift
channelController
            .typingUsersPublisher
            .sink(receiveValue: { 
                // Process the changes related to typing users here
            })
            .store(in: &cancellables)
```

### Example: Typing Indicator

Let's build a simple `UIView` that shows which user is currently typing in the channel using the `typingUsersPublisher`

```swift

class TypingIndicatorView: UIView {
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
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTypingUsers(_ typingUsers: Set<ChatUser>) {
        guard let typingUser = typingUsers.first else {
            labelView.text = ""
            return
        }
        
        labelView.text = "\(typingUser.name ?? typingUser.id) is typing ..."
    }
}

class ViewController: UIViewController {
    var controller: ChatChannelController!
    var cancellables: Set<AnyCancellable> = []

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

        controller.typingUsersPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] typingUsers in
                let otherUsersTyping = typingUsers.filter({ $0.id != self?.controller.client.currentUserId })
                self?.typingIndicatorView.setTypingUsers(otherUsersTyping)
            }.store(in: &cancellables)
        
        navigationItem.titleView = typingIndicatorView
    }
}

```

## ChatChannelMemberListController

`ChatChannelMemberListController` allows you to observe and mutate data and observing changes for a list of channel members based on the provided query.

### Publishers in `MemberListController`

The `membersChanges` publisher will emit a new value whenever the list of channel members based on the provided query changes.

```swift
 memberListController
            .membersChangesPublisher
            .sink(receiveValue: { 
                // Use the member list here
             })
            .store(in: &cancellables)
```

### Example: Listing Members

This example uses the `membersChangesPublisher` to observe the changes to the members on the channel `messaging:123`

```swift
class MembersSearchResultsView: UIView {
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
        fatalError("init(coder:) has not been implemented")
    }

    func setMembers(_ members: [ChatChannelMember]) {
        let membersStr = members.map { $0.name ?? $0.id }.joined(separator: ", ")
        labelView.text = membersStr
    }
}

class ViewController: UIViewController {
    var controller: ChatChannelMemberListController!
    var cancellables: Set<AnyCancellable> = []
    
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
        
        controller.synchronize {error in
            if error != nil {
                log.assertionFailure(error!)
            }
        }
        
        controller.membersChangesPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                if let updatedMembers = self?.controller.members {
                    self?.membersSearchResultsView.setMembers(Array(updatedMembers))
                }
            }.store(in: &cancellables)
        
        navigationItem.titleView = membersSearchResultsView
    }
}

```

## ChannelMemberController

`ChatChannelMemberController` allows you to observe and mutate data and observing changes of a specific chat member.

### Publishers in `ChannelMemberController`

The `memberChangePublisher` emits a new value protocol every time the member changes.

```swift
 memberController
            .memberChangePublisher
            .sink(receiveValue: {  
                // Process the member changes here.
            })
            .store(in: &cancellables)
```
