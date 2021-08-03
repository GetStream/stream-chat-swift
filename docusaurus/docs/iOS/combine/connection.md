---
title: Connection
---

## ConnectionController

`ChatConnectionController` allows you to connect/disconnect the `ChatClient` and observe connection events.

## Publishers in `ChatConnectionController`

The `connectionStatusPublisher` will emit a new value every time the connection status changes.

```swift
connectionController.connectionStatusPublisher
            .sink(receiveValue: { 
                // Use the connection status here
            })
            .store(in: &cancellables)
```

## Example: Connection Status

Let's build a simple UIView that shows the current connection status.

```swift
class ConnectionStatusView: UIView {
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
}

class ViewController: UIViewController {
    var controller: ChatConnectionController!
    var cancellables: Set<AnyCancellable> = []
    
    var connectionStatusView: ConnectionStatusView = {
        var view = ConnectionStatusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        controller = ChatClient.shared.connectionController()
        
        controller.connectionStatusPublisher.receive(on: RunLoop.main).sink { [weak self] connectionStatus in
            self?.connectionStatusView.status = connectionStatus
        }.store(in: &cancellables)

        navigationItem.titleView = connectionStatusView
    }
}
```