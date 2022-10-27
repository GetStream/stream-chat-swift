---
title: Events Controllers
---

## EventsController

`EventsController` allows you to subscribe to chat events. You can receive all events or only to events for a specific channels.

### Events Controller Delegate

Classes that conform to the `EventsControllerDelegate` protocol can be used to receive events from the controller.

```swift
func eventsController(_ controller: EventsController, didReceiveEvent event: Event)
```

### Client Events

```swift
let eventsController: EventsController = client.eventsController()
```

### Channel Events

```swift
let eventsController: EventsController = channel.eventsController()
```

### Example: Local Notifications

In this example we create a custom `ChatChannelListVC` that shows a local notification every time a new message event is received.

```swift
class DemoChannelListVC: ChatChannelListVC, EventsControllerDelegate {
    lazy var eventsController: EventsController = controller.client.eventsController()

    override func viewDidLoad() {
        super.viewDidLoad()
        eventsController.delegate = self
    }

    func eventsController(_: EventsController, didReceiveEvent event: Event) {
        guard let event = event as? MessageNewEvent else { return }

        let message = event.message

        let content = UNMutableNotificationContent()
        content.title = "\(message.author.name ?? message.author.id) @ \(event.channel.name ?? event.channel.cid.id)"
        content.body = message.text

        let request = UNNotificationRequest(
            identifier: message.id,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                log.error("Error when showing local notification: \(error)")
            }
        }
    }
}
```
