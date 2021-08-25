---
title: Push Notifications
---

Push notifications can be configured to receive updates when the application is closed or on the background. Stream Chat sends push notification to channel members that are not online and have at least one registered device. Stream supports both **Certificate-based provider connection trust (.p12 certificate)** and **Token-based provider connection trust (JWT)**. Token-based authentication is the preferred way to configure push. 

:::note
You can find more on setting up push [here](https://getstream.io/chat/docs/php/push_ios/?language=swift). Make sure you've taken care of authentication before proceeding to the next steps.
:::

To receive push notifications from the Stream server the first step you need to do is register the device. To do this you need to call `UIApplication.shared.registerForRemoteNotifications()` and send the token from `application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)`.

Here is the boilerplate code that you can add to your `AppDelegate`:

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    guard ChatClient.shared.currentUserId != nil else {
        log.warning("cannot add the device without connecting as user first, did you call connectUser")
        return
    }

    ChatClient.shared.currentUserController().addDevice(token: deviceToken) { error in
        if let error = error {
            log.warning("adding a device failed with an error \(error)")
        }
    }
}
```

Because devices are linked to chat users, you should request the device token in the `connectUser` completion block

```swift
ChatClient.shared.connectUser(
    userInfo: UserInfo(
        id: "leia_organa",
        name: "Leia Organa",
        imageURL: URL(string: "https://cutt.ly/SmeFRfC")
    ),
    token: token
) { error in
    if let error = error {
        log.error("connecting the user failed \(error)")
        return
    }
    UNUserNotificationCenter
        .current()
        .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
}
```

:::note
Push notifications can be tricky to setup correctly, make sure to check for errors and settings on the [Dashboard](https://getstream.io/dashboard/)
:::

### Removing devices

```swift
guard let deviceId = ChatClient.shared.currentUserController().currentUser?.devices.last?.id else {
    return
}

ChatClient.shared.currentUserController().removeDevice(id: deviceId) { error in
    if let error = error {
        log.warning("removing the device failed with an error \(error)")
    }
}
```
