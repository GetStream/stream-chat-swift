---
title: Event Controllers
---

## EventsController

`EventsController` allows you subscribe to the system events published by the SDK.

### Publishers in `EventsController`

The `allEventsPublisher` will emit a new value every time an event is published by the SDK.

```swift
 eventsController
                .allEventsPublisher
                .sink { 
                    print($0) // Process the event here
                }.store(in: &cancellables)
```

The `EventsController` also allows you to subscribe to specific events using the `public func eventPublisher<T: Event>(_ eventType: T.Type)` method.
This method returns a publisher that can be used to observe a specific event of type `T`.

```swift
 // Subscribe for `MessageUpdatedEvent`
eventsController
                .eventPublisher(MessageUpdatedEvent.self) // The type of the event you want to observe
                .filter { [messageId = messageController.messageId] in 
                    $0.messageId == messageId 
                }
                .sink { 
                    print($0) // Process the update to the message
                }
                .store(in: &cancellables)
```

## Example: Subscribing to the `MessageNewEvent`

```swift
class YourCustomChannelListVC: ChatChannelListVC {
    var eventsController: EventsController!
    var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventsController = controller.client.eventsController()
        eventsController
            .eventPublisher(MessageNewEvent.self)
            .receive(on: RunLoop.main)
            .sink { messageNewEvent in
                // do what you need with the event
                print(messageNewEvent.messageId)
            }
    }
}
```
