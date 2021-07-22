---
title: ChatConnectionController
---

`ChatConnectionController` allows you to connect/disconnect the `ChatClient` and observe connection events.

## ChatConnectionControllerDelegate

Classes that conform to this protocol will receive changes to the connection status.

```swift
/// The controller observed a change in connection status.
func connectionController(
    _ controller: _ChatConnectionController<ExtraData>,
    didUpdateConnectionStatus status: ConnectionStatus
)
```

## Example - Unread Count Indicator

Let's build a simple UIView that shows the current connection status.

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