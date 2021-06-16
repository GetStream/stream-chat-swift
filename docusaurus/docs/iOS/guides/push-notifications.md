---
title: Push Notifications
---

First step on a way to setting up push notifications is authentication.
Stream supports both **Certificate-based provider connection trust (.p12 certificate)** and **Token-based provider connection trust (JWT)**. Token based authentication is the preferred way to setup push notifications. This method is easy to setup and provides strong security. You can find more on setting up authentication [here](https://getstream.io/chat/docs/php/push_ios/?language=swift).

## Testing Push Notifications setup

Once authentication is taken care of, you can test your setup as explained below.

First of all make sure you have at least one [device associated](#managing-devices-for-testing-purposes).

If the device you want to test notifications on is already added to the list, you can now test pushes:

    stream chat:push:test

This will do several things for you:

1. Pick a random message from a channel that this user is part of
2. Use the notification templates configured for your push providers to render the payload using this message
3. Send this payload to all of the user's devices
   
## Managing devices for testing purposes

For testing purposes you can manage devices using Stream CLI:

### Adding devices
    stream chat:push:device:add

### Removing devices
    stream chat:push:device:delete

### Getting the list of all devices registered for pushes
    stream chat:push:device:get

## Managing devices in client code

If you want for a user to receive push notifications, you need to request permissions for this. One of the most common places to do so is in `AppDelegate`'s `application(_:didFinishLaunchingWithOptions:)`, for instance like this:

```swift
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    UNUserNotificationCenter
        .current() 
        .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Permission granted: \(granted)")
        }
    return true
}
```

In case if the device was successfully registered for receiving push notifications, your app will receive an `application(_:didRegisterForRemoteNotificationsWithDeviceToken)` callback. At this point you should send an obtained device token to StreamChat's backend to finish the device's registration for push notifications.

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    chatClient.currentUserController().addDevice(token: deviceToken) { error in
        if let error = error {
            // handle error
            print(error)
        }
    }
}
```

### Removing devices

```swift
let deviceId = chatClient.currentUserController().currentUser!.devices.last!.id

chatClient.currentUserController().removeDevice(id: deviceId) { error in
    if let error = error {
        // handle error
        print(error)
    }
}
```

## Push Delivery Logic

Only new messages are pushed to mobile devices, all other chat events are only send to WebSocket clients and webhook endpoints if configured.

Push message delivery follows the following logic:

* Only channel members can receive push messages
* Members that are currently [watching the channel](https://getstream.io/chat/docs/ios-swift/watch_channel/?language=swift) do not receive push messages
* Messages added within a thread are only sent to users that are part of that thread (they posted at least one message or were mentioned)
* Messages from muted users are not sent
* Messages are sent to all registered devices for a user (up to 25)
* Don't try to register devices for anonymous users (API will ignore but will eat from rate limit budget)
* Up to 100 members of a channel will receive push notifications
* If `skip_push` parameter for a message was set for `true`, there will be no push
* `push_notifications` should be enabled (default) on the channel

## Rich Push Notifications

If you want to modify and enhance push notifications appearance, you need to add a `Notification Service Extension`. This is a common iOS development process and there is no nuances specific to StreamChat, so any guide on the topic will do. For instance,[ this one](https://www.raywenderlich.com/8277640-push-notifications-tutorial-for-ios-rich-push-notifications#toc-anchor-007). 