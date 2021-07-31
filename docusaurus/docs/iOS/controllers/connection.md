---
title: Connection
---

## ConnectionController

`ChatConnectionController` allows you to connect/disconnect the `ChatClient` and observe connection events.

## Connection Delegate

Classes that conform to the `ChatConnectionControllerDelegate` protocol will receive changes to the connection status (ie. online, offline, connecting, ...).

```swift
/// The controller observed a change in connection status.
func connectionController(
    _ controller: ChatConnectionController,
    didUpdateConnectionStatus status: ConnectionStatus
)
```

## Example: Connection Status

Let's build a simple UIView that shows the current connection status.

```swift
class ConnectionStatusView: UIView, ChatConnectionControllerDelegate {
    var status = ConnectionStatus.connecting {
        didSet {
            labelView.text = "Connection status: \(status)"
        }
    }
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
    func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus) {
        self.status = status
    }
}

class ViewController: UIViewController {
    var controller: ChatConnectionController!
    var connectionStatusView: ConnectionStatusView = {
        var view = ConnectionStatusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        controller = ChatClient.shared.connectionController()
        controller.delegate = connectionStatusView

        connectionStatusView.status = controller.connectionStatus
        navigationItem.titleView = connectionStatusView
    }
}
```