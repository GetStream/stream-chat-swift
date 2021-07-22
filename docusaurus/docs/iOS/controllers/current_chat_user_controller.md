---
title: CurrentChatUserController
---

`CurrentChatUserController` allows you to observe and mutate the current user.

## CurrentChatUserControllerDelegate

Classes that conform to this protocol will receive changes to the current user and changes to the unread count.

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

## Example - Unread Count Indicator

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