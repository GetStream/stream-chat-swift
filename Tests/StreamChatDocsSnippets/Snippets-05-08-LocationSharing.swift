//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/location-sharing/

import Foundation
import StreamChat

struct Snippets_05_08_LocationSharing {
    var channelId: ChannelId!
    var chatClient: ChatClient!
    var liveLocationMessageId: MessageId!

    func sendingStaticLocation() {
        /// Get a channel controller for the channel.
        let channelController = chatClient.channelController(for: ChannelId(type: .messaging, id: "general"))

        /// Send a message with a static location.
        let location = LocationInfo(latitude: 10, longitude: 10)
        channelController.sendStaticLocation(location)

        /// Alternatively, you can create a new message with a `NewLocationInfo` object and endAt as nil.
        let newLocation = NewLocationInfo(latitude: 10, longitude: 10, endAt: nil)
        channelController.createNewMessage(text: "", location: newLocation)
    }

    func startingLiveLocationSharing() {
        /// Get a channel controller for the channel.
        let channelController = chatClient.channelController(for: ChannelId(type: .messaging, id: "general"))

        /// Send a message with a live location with the initial coordinates.
        let location = LocationInfo(latitude: 10, longitude: 10)
        let oneMinuteFromNow = Date().addingTimeInterval(60)
        channelController.startLiveLocationSharing(location, endDate: oneMinuteFromNow)
    }

    func stoppingLiveLocationSharing() {
        /// Get the message controller for the live location message
        let messageController = chatClient.messageController(
            cid: channelId,
            messageId: liveLocationMessageId
        )

        /// Stop live location sharing
        messageController.stopLiveLocationSharing()
    }

    // Updating live location
    class LiveLocationTracker {
        let currentUserController: CurrentChatUserController

        init(chatClient: ChatClient) {
            /// Get the current user controller.
            currentUserController = chatClient.currentUserController()

            /// Set delegate to receive live location updates.
            currentUserController.delegate = self

            /// Load active live locations (call only once at app start or when chat is initialized)
            currentUserController.loadActiveLiveLocationMessages()
        }

        /// Update location when device location changes.
        func locationDidUpdate(_ newLocation: LocationInfo) {
            currentUserController.updateLiveLocation(newLocation)
        }
    }

    // Events
    class ChannelLocationsObserver {
        let eventsController: EventsController
        let currentChannelId: ChannelId

        init(chatClient: ChatClient, channelId: ChannelId) {
            currentChannelId = channelId
            eventsController = chatClient.eventsController()
            eventsController.delegate = self
        }
    }
}

/// The location tracking the app implements, which the delegate methods below call.
extension Snippets_05_08_LocationSharing.LiveLocationTracker {
    func startLocationTracking() {}

    func stopLocationTracking() {}
}

// Updating live location (2)
extension Snippets_05_08_LocationSharing.LiveLocationTracker: CurrentChatUserControllerDelegate {

    /// Called when the user starts sharing a live location and it wasn't already sharing a live location
    func currentUserControllerDidStartSharingLiveLocation(
        _ controller: CurrentChatUserController
    ) {
        // Start location monitoring (Needs to be implemented by the application)
        startLocationTracking()
    }

    /// Called when all live location sharing stops
    func currentUserControllerDidStopSharingLiveLocation(
        _ controller: CurrentChatUserController
    ) {
        // Stop location monitoring
        stopLocationTracking()
    }

    /// Called when active live location messages change
    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeActiveLiveLocationMessages messages: [ChatMessage]
    ) {
        // You can use this delegate method to track the active live location messages and
        // if needed render all of them in a UI component or you can use this for finer control
        // when to start or stop tracking locations.
    }

    /// Called when a live location update fails
    func currentUserController(
        _ controller: CurrentChatUserController,
        didFailToUpdateLiveLocation location: SharedLocation,
        with error: Error
    ) {
        // Handle error if needed
    }

}

// Events
extension Snippets_05_08_LocationSharing.ChannelLocationsObserver: EventsControllerDelegate {
    func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
        /// Make sure the event is for the current channel.
        if let event = event as? MessageNewEvent,
           event.cid == currentChannelId,
           let sharedLocation = event.message.sharedLocation {
            // Add the new location to the map.
            suppressUnusedWarning(sharedLocation)
        } else if let event = event as? MessageUpdatedEvent,
                  event.cid == currentChannelId,
                  let sharedLocation = event.message.sharedLocation {
            // Update the location on the map.
            suppressUnusedWarning(sharedLocation)
        }
    }
}
