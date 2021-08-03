---
title: Message Controllers
---

## MessageController

`ChatMessageController` allows you to observe and mutate data and observing changes for one message and its replies.

### Publishers in `ChatMessageController`

The `messageChangePublisher` emits a new value every time the message changes.

```swift
messageController
            .messageChangePublisher
            .sink(receiveValue: { 
                // Process the changes in the message here
            })
            .store(in: &cancellables)
```

The `repliesChangesPublisher` emits a new value every time the list of the replies of the message has some changes.

```swift
messageController
            .repliesChangesPublisher
            .sink(receiveValue: { 
                // Process the changes to message replies here
            })
            .store(in: &cancellables)
```

### Example: Message Detail

```swift
class MessageDetailView: UIView {
    var message: ChatMessage! {
        didSet {
            updateContent()
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

    func updateContent() {
        let messageText = message?.text ?? ""
        let repliesCount = message?.replyCount ?? 0

        labelView.text = "Text: \(messageText) Replies: \(repliesCount)"
    }
}

class ViewController: UIViewController {
    var controller: ChatMessageController!
    var cancellables: Set<AnyCancellable> = []

    var messageDetailView: MessageDetailView = {
        var view = MessageDetailView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cid = ChannelId(type: .messaging, id: "E9BF5FCE-1")
        controller = ChatClient.shared.messageController(cid: cid, messageId: "91AC67C6-C2AF-486E-8552-08E6F9B48D85")

        controller.synchronize { error in
            if error != nil {
                log.assertionFailure(error!)
                return
            }
            /// set the intial state to the view
            self.messageDetailView.message = self.controller.message
        }
        
        controller.messageChangePublisher.receive(on: RunLoop.main).sink { [weak self] messageChange in
            print("Message changed!")
            self?.messageDetailView.message = self?.controller.message
        }.store(in: &cancellables)
        
        controller.repliesChangesPublisher.receive(on: RunLoop.main).sink { [weak self] messageChange in
            print("Replies changed!")
            self?.messageDetailView.message = self?.controller.message
        }.store(in: &cancellables)

        navigationItem.titleView = messageDetailView
    }
}

```
