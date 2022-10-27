---
title: User Controllers
---

## CurrentUserController

`CurrentChatUserController` allows you to observe and mutate the current user.

### CurrentUser Delegate

Classes that conform to the `CurrentChatUserController` protocol will receive changes to the current user and changes to the unread count.

```swift
/// The controller observed a change in the `UnreadCount`.
func currentUserController(
    _ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount
)
    
/// The controller observed a change in the `CurrentUser` entity.
func currentUserController(
    _ controller: CurrentChatUserController,
    didChangeCurrentUser: EntityChange<CurrentChatUser>
)
```

### Example: Unread Count

Let's build a simple UIView that shows the current unread count for the current user.

```swift
class UnreadCountIndicatorView: UIView, CurrentChatUserControllerDelegate {

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

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount) {
        unreadCount = didChangeCurrentUserUnreadCount.messages
    }
}

class ViewController: UIViewController {
    var currentUserController: CurrentChatUserController!
    var unreadCountIndicatorView: UnreadCountIndicatorView = {
        var view = UnreadCountIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        currentUserController = ChatClient.shared.currentUserController()
        currentUserController.delegate = unreadCountIndicatorView
        currentUserController.synchronize()
        navigationItem.titleView = unreadCountIndicatorView
    }
}
```

## UserListController

`ChatUserListController` allows you to observe a list of users based on the provided query.

### UserList Delegate

Classes that conform to the `ChatUserListControllerDelegate` protocol will receive changes to the queries list of users.

```swift
func controller(
    _ controller: ChatUserListController,
    didChangeUsers changes: [ListChange<ChatUser>]
)
```

## UserController

`ChatUserController` allows you to observe and mutate the current user.

### UserControllerDelegate

Classes that conform to this protocol will receive changes to chat users. 

```swift
func userController(
    _ controller: ChatUserController,
    didUpdateUser change: EntityChange<ChatUser>
)
```

## UserSearchController

`ChatUserSearchController` allows you to query users and to observe changes to the users matching the query.

### UserSearch Delegate

Classes that conform to the `ChatUserSearchControllerDelegate` protocol will receive changes to user searches.

```swift
/// The controller changed the list of observed users.
///
/// - Parameters:
///   - controller: The controller emitting the change callback.
///   - changes: The change to the list of users.
///
func controller(
    _ controller: ChatUserSearchController,
    didChangeUsers changes: [ListChange<ChatUser>]
)
```

### Example: User Search

This small example uses the controller to search users using the `autocomplete` query filter and binds a view as its delegate.

```swift
class UsersListView: UIView, ChatUserSearchControllerDelegate {
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

    func controller(_ controller: ChatUserSearchController, didChangeUsers changes: [ListChange<ChatUser>]) {
        let names = controller.users.map({ $0.name ?? $0.id }).joined(separator: ", ")
        labelView.text = "users: \(names)"
    }
}

class ViewController: UIViewController {
    var controller: ChatUserSearchController!

    var usersListView: UsersListView = {
        var view = UsersListView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let query = UserListQuery.init(filter: .autocomplete(.name, text: "t"), sort: [], pageSize: 10)
        controller = ChatClient.shared.userSearchController()
        controller.delegate = usersListView
        controller.search(query: query)
        navigationItem.titleView = usersListView
    }
}
```
