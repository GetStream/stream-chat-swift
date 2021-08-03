---
title: User Controllers
---

## CurrentUserController

`CurrentChatUserController` allows you to observe and mutate the current user.

### Publishers in `CurrentUserController`

The `currentUserChangePublisher` emits a new value every time the current user changes.

```swift
currentUserController
            .currentUserChangePublisher
            .sink(receiveValue: { 
                // Use the new user here
            })
            .store(in: &cancellables)
```

The `unreadCountPublisher` emits a new value every time the unread count changes.

```swift
currentUserController
            .unreadCountPublisher
            .sink(receiveValue: { 
                // Use the unread count value here
            })
            .store(in: &cancellables)
```

### Example: Unread Count

Let's build a simple UIView that shows the current unread count for the current user.

```swift
class UnreadCountIndicatorView: UIView {

    var unreadCount = 0 {
        didSet {
            unreadCountLabelView.text = "You have \(unreadCount) unread messages"
        }
    }

    var unreadCountLabelView: UILabel = {
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(unreadCountLabelView)
        NSLayoutConstraint.activate([
            unreadCountLabelView.topAnchor.constraint(equalTo: topAnchor),
            unreadCountLabelView.bottomAnchor.constraint(equalTo: bottomAnchor),
            unreadCountLabelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            unreadCountLabelView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class ViewController: UIViewController {
    var currentUserController: CurrentChatUserController!
    var cancellables: Set<AnyCancellable> = []
    
    var unreadCountIndicatorView: UnreadCountIndicatorView = {
        var view = UnreadCountIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentUserController = ChatClient.shared.currentUserController()
        currentUserController.synchronize()
        
        currentUserController.unreadCountPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] unreadCount in
            self?.unreadCountIndicatorView.unreadCount = unreadCount.messages
        }.store(in: &cancellables)
        
        navigationItem.titleView = unreadCountIndicatorView
    }
}
```

## UserListController

`ChatUserListController` allows you to observe a list of users based on the provided query.

### Publishers in `ChatUserListController`

The `usersChangesPublisher` will emit a new value every time there is a change in the list of the users that match the query.

```swift
userListController
            .usersChangesPublisher
            .sink(receiveValue: { 
                // Use the new users here
            })
            .store(in: &cancellables)
```

## UserController

`ChatUserController` allows you to observe and mutate the current user.

### Publishers in `ChatUserController`

The `userChangePublisher` will emit a new value every time the user changes.

```swift
userController
            .userChangePublisher
            .sink(receiveValue: { 
                // Use the new user here
            })
            .store(in: &cancellables)
```
