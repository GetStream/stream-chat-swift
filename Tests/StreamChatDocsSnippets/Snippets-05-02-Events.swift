//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/event-object/

import Combine
import Foundation
import StreamChat
import UIKit

@MainActor
struct Snippets_05_02_Events {
    var cancellables = Set<AnyCancellable>()
    var channelController: ChatChannelController!
    var client: ChatClient!

    mutating func listeningForEvents() {
        // There are 2 ways to listen for events
        // 1. Use an EventsController
        // 2. Use the appropriate controller's delegate methods
        // ChannelController delegate methods to listen Channel events
        // CurrentUserController delegate methods to listen Current User events
        /// * Delegates *

        /// * Combine *

        channelController.messagesChangesPublisher
          .receive(on: RunLoop.main)
          .sink { changes in
            // animate the changes to the message list
          }
          .store(in: &cancellables)
    }

    class MyViewController: UIViewController, EventsControllerDelegate {
      var client: ChatClient!
      var eventsController: EventsController!

      override func viewDidLoad() {
        super.viewDidLoad()
        eventsController = client.eventsController()
        eventsController.delegate = self
      }

      func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        // Handle any event received
        switch event {
        case let event as MessageNewEvent:
          // handle MessageNewEvent
          print(event.message.text)
        default:
          break
        }
      }
    }

    class ChannelViewController: ChatChannelControllerDelegate {
      let channelController: ChatChannelController

      init(client: ChatClient) {
        channelController = client.channelController(for: .init(type: .messaging, id: "general"))
        channelController.delegate = self
        channelController.synchronize()
      }

      func channelController(_ channelController: ChatChannelController, didUpdateMessages changes: [ListChange<ChatMessage>]) {
        // animate the changes to the message list
      }
    }

    // `MyViewController` is declared by an earlier fence too, so this one stays local
    func listeningForEvents2() {
        // There are 2 ways to listen for events
        // 1. Use an EventsController
        class MyViewController: UIViewController, EventsControllerDelegate {
          var client: ChatClient!
          var eventsController: EventsController!

          override func viewDidLoad() {
            super.viewDidLoad()
            eventsController = client.eventsController()
            eventsController.delegate = self
          }

          func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
            // Handle any event received
            switch event {
            case let event as MessageNewEvent:
              // handle MessageNewEvent
              print(event.message.text)
            default:
              break
            }
          }
        }
        // 2. Use the appropriate controller's delegate methods
        // ChannelController delegate methods to listen Channel events
        // CurrentUserController delegate methods to listen Current User events
    }

    func eventTypes() {}

    class PresenceObserver: EventsControllerDelegate {
      let eventsController: EventsController

      init(client: ChatClient) {
        eventsController = client.eventsController()
        eventsController.delegate = self
      }

      func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if let event = event as? UserPresenceChangedEvent {
          // Update your UI with event.user and event.user.isOnline
          suppressUnusedWarning(event)
        }
      }
    }

    func connectionEvents() {
        let connectionController = client.connectionController()

        // The controller holds its delegate weakly: keep a strong reference to both
        let connectionDelegate = ConnectionDelegate()
        connectionController.delegate = connectionDelegate
    }

    class ConnectionDelegate: ChatConnectionControllerDelegate {
      func connectionController(_ controller: ChatConnectionController,
                   didUpdateConnectionStatus status: ConnectionStatus) {
         // handle connection change
      }
    }

    // `MyViewController` is declared by an earlier fence too, so this one stays local
    func stopListeningForEvents() {
        // There are 2 ways to listen for events
        // 1. Use an EventsController
        class MyViewController: UIViewController, EventsControllerDelegate {
          var client: ChatClient!
          var eventsController: EventsController!

          override func viewDidLoad() {
            super.viewDidLoad()
            eventsController = client.eventsController()
            eventsController.delegate = self
          }

          override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            // stop listening for events by releasing the controller
            eventsController = nil
          }

          func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
            // Handle any event received
            switch event {
            case let event as MessageNewEvent:
              // handle MessageNewEvent
              print(event.message.text)
            default:
              break
            }
          }
        }
    }

    func toAChannel() {
        // Send channel events using the channel's events controller
        let channelEventsController = channelController.eventsController()
        let event = MyCustomEvent(text: "This is my custom text")
        channelEventsController.sendEvent(event)

        // Or with the state layer: try await chat.sendEvent(event)

        // Subscribe for custom events works with delegation pattern
    }

    struct MyCustomEvent: CustomEventPayload {
      static let eventType: EventType = "my_custom_event"

      let text: String
    }

    final class MyChannelViewModel: EventsControllerDelegate {
      // eventsController needs to be retained
      private var eventsController: EventsController?

      func setupEventListening(chatClient: ChatClient) {
        eventsController = chatClient.eventsController()
        eventsController?.delegate = self
      }

      // EventsControllerDelegate method
      func eventsController(_: EventsController, didReceiveEvent event: Event) {
        // ignore regular events, we only care about custom channel event
        guard let channelEvent = event as? UnknownChannelEvent else {
          return
        }

        // Filter only `MyCustomEvent` event
        guard let customPayload = channelEvent.payload(ofType: MyCustomEvent.self) else {
          return
        }

        print("Received a custom event with text \(customPayload.text)")
      }
    }
}
