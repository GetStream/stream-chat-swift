---
title: Message Controllers
---

## MessageController

`ChatMessageController` allows you to observe and mutate data and observing changes for one message and its replies.

### Message Delegate

Classes that conform to the `ChatMessageControllerDelegates` protocol will receive data and changes for a message and its replies.

```swift
/// The controller observed a change in the `ChatMessage`.
func messageController(
    _ controller: ChatMessageController,
    didChangeMessage change: EntityChange<ChatMessage>
)

/// The controller observed changes in the replies of the observed `ChatMessage`.
func messageController(
    _ controller: ChatMessageController,
    didChangeReplies changes: [ListChange<ChatMessage>]
)
```

### Example: Message Detail

```swift
class MessageDetailView: UIView, ChatMessageControllerDelegate {
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

    func messageController(_ controller: ChatMessageController, didChangeMessage change: EntityChange<ChatMessage>) {
        message = controller.message
    }

    func messageController(_ controller: ChatMessageController, didChangeReplies changes: [ListChange<ChatMessage>]) {
        message = controller.message
        print("list of replies for this message changed!")
    }
}

class ViewController: UIViewController {
    var controller: ChatMessageController!

    var messageDetailView: MessageDetailView = {
        var view = MessageDetailView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cid = ChannelId(type: .messaging, id: "E9BF5FCE-1")
        controller = ChatClient.shared.messageController(cid: cid, messageId: "91AC67C6-C2AF-486E-8552-08E6F9B48D85")
        controller.delegate = messageDetailView

        controller.synchronize { error in
            if error != nil {
                log.assertionFailure(error!)
                return
            }
            /// set the intial state to the delegated view
            self.messageDetailView.message = self.controller.message
        }

        navigationItem.titleView = messageDetailView
    }
}
```