---
title: Push Notifications
---

Push notifications can be configured to receive updates when the application is closed or on the background. Stream Chat sends push notification to channel members that are not online and have at least one registered device. Stream supports both **Certificate-based provider connection trust (.p12 certificate)** and **Token-based provider connection trust (JWT)**. Token-based authentication is the preferred way to configure push notifications. 

:::note
You can find more on setting up push [here](https://getstream.io/chat/docs/php/push_ios/?language=swift). Make sure you've taken care of authentication before proceeding to the next steps.
:::

### Setup

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

### Redirecting From Notification To App

In order to redirect the user from notifications to a specific screen in your app, you need to create a `UNUserNotificationCenterDelegate`, your delegate will be called when the app is open from a push notification.

The following code shows how to open the app on the channel after tapping on the push notification:

```swift
class SampleNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        defer {
            completionHandler()
        }

        guard let notificationInfo = try? ChatPushNotificationInfo.init(content:response.notification.request.content) else {
            return
        }

        guard let cid = notificationInfo.cid else {
            return
        }

        guard case UNNotificationDefaultActionIdentifier = response.actionIdentifier else {
            return
        }
        
        /// initialize ChatClient and connect the user
        let config = ChatClientConfig(apiKey: .init("<# Api Key Here #>"))
        ChatClient.shared = ChatClient(config: config)
        
        let token = Token(stringLiteral: "<# User Token Here #>")
        ChatClient.shared = ChatClient(config: config)
        ChatClient.shared.connectUser(
            userInfo: .init(id: "<# User ID Here #>"),
            token: token
        ) { error in
            print("debugging: connectUser completion called")
            if let error = error {
                print("debugging: connectUser completion errored")
                log.error("connecting the user failed \(error)")
                return
            }
        }

        /// initialize the Channel VC
        let channelVC = ChatMessageListVC.init()
        channelVC.channelController = ChatClient.shared.channelController(for: cid)

        /// navigate to the Channel VC
        let window = navigationController.view.window!
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromRight, animations: {
           window.rootViewController = channelVC
        })
    }
```

Make sure to set your class as `UNUserNotificationCenter` delegate while your application is loading (ie. `AppDelegate` or `SceneDelegate`)

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        
        guard let navigationController = UIStoryboard(
            name: "Main",
            bundle: nil
        ).instantiateInitialViewController() as? UINavigationController else { return }

        window.rootViewController = navigationController
        coordinator = SampleNotificationDelegate(navigationController: navigationController)

        UNUserNotificationCenter.current().delegate = coordinator

        /// ...
    }

}
```
## Customizing Push Notifications

Stream sends push notifications ready for iOS to be presented to the user. If you followed this document until now, you app is already receiving clear messages via push notifications.

In many cases you want the push message to be customized, the best way to do this is via a service extension. A service extension will capture all notifications and allows you to modify its content before presenting it to the user.

### Notification Service Extension

These are the main steps needed to setup your service extension to customize push notifications:

- Add a Notification Service Extension to your application
- Use the `ChatRemoteNotificationHandler` class from `StreamChat` to retrieve the full content of the notification
- Modify the `UNNotificationContent` object as needed

More documentation on how to add a Notification Service Extension is available [here](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension).

If your application persist chat data on the device you need to create an App Group and make sure that your application and the service extension are configured to use it. You can find the instructions for this [here](#setting-up-app-groups).

Here's a minimal example of a `NotificationService` class:

```swift
import StreamChat
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var request: UNNotificationRequest?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        self.request = request

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return
        }

        var config = ChatClientConfig(apiKey: .init("<# Your API Key Here #>"))

        /// uncomment this if you persist data on the device
        /// config.isLocalStorageEnabled = true
        /// config.applicationGroupIdentifier = "<# App Group ID Here #>"

        let client = ChatClient(config: config)
        let token = Token(stringLiteral: "<# User Token Here #>")
        client.setToken(token: token)

        let chatHandler = ChatRemoteNotificationHandler(client: client, content: content)

        let chatNotification = chatHandler.handleNotification { chatContent in
            switch chatContent {
            case let .message(message):
                content.title = message.author.name ?? ""
                content.subtitle = message.text
            default:
                content.title = "You received an update to one conversation"
                contentHandler(content)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = request?.content.mutableCopy() as? UNMutableNotificationContent {
            contentHandler(bestAttemptContent)
        }
    }
}
```
Let's summarize the most important steps:

- The `ChatClient` is initialized with Api Key and Token, `connectUser` must not be used in a service extension
- `chatHandler.handleNotification` completion block receives a `ChatPushNotificationContent` 
- `ChatPushNotificationContent` is handled for the message case, in that case it will contain a regular `ChatMessage` model

#### Complete Example

Here is a more complete example which adds an image attachment to the notification content.

```swift
import StreamChat
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var request: UNNotificationRequest?

    func addAttachments(
        url: URL,
        content: UNMutableNotificationContent,
        identifier: String = "image",
        completion: @escaping (UNMutableNotificationContent) -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: url) { (downloadedUrl, _, _) in
            defer {
                completion(content)
            }

            guard let downloadedUrl = downloadedUrl else {
                return
            }
          
            guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
                return
            }
          
            let localURL = URL(fileURLWithPath: path).appendingPathComponent(url.lastPathComponent)
          
            do {
                try FileManager.default.moveItem(at: downloadedUrl, to: localURL)
            } catch {
                return
            }

            guard let attachment = try? UNNotificationAttachment(identifier: identifier, url: localURL, options: nil) else {
                return
            }

            content.attachments = [attachment]
        }
        task.resume()
    }

    func addMessageAttachments(
        message: ChatMessage,
        content: UNMutableNotificationContent,
        completion: @escaping (UNMutableNotificationContent) -> Void
    ) {
        if let imageURL = message.author.imageURL {
            addAttachments(url: imageURL, content: content) {
                completion($0)
            }
            return
        }
        if let attachment = message.imageAttachments.first {
            addAttachments(url: attachment.imageURL, content: content) {
                completion($0)
            }
            return
        }
    }

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        self.request = request

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return
        }

        var config = ChatClientConfig(apiKey: .init("<# Your API Key Here #>"))
        /// config.isLocalStorageEnabled = true
        /// config.applicationGroupIdentifier = "<# App Group ID Here #>"

        let token = "<# User Token Here #>"
        let client = ChatClient(config: config)
        client.setToken(token: token)

        let chatHandler = ChatRemoteNotificationHandler(client: client, content: content)

        let chatNotification = chatHandler.handleNotification { chatContent in
            switch chatContent {
            case let .message(messageNotification):
                content.title = (messageNotification.message.author.name ?? "somebody") + (" on \(messageNotification.channel?.name ?? "a conversation with you")")
                content.subtitle = ""
                content.body = messageNotification.message.text
                self.addMessageAttachments(message: messageNotification.message, content: content) {
                    contentHandler($0)
                }
            default:
                content.title = "You received an update to one conversation"
                contentHandler(content)
            }
        }
        
        if !chatNotification {
            /// this was not a notification from Stream Chat
            /// perform any other transformation to the notification if needed
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = request?.content.mutableCopy() as? UNMutableNotificationContent {
            contentHandler(bestAttemptContent)
        }
    }
}
```

### Setting Up App Groups

To share data we need to create a shared container between the main app and the service extension. You can do this by adding an app group capability within your projects “Signing & Capabilities” section.

Note that the App Group is turned into red when you didn’t add it to your App Identifier yet. You can do this by logging into your account at https://developer.apple.com/account/resources/identifiers

Make sure to use the same group for both targets (app and extension). When you have both configured, you need to adjust your `ChatClient` setup code and add this to the config object:

```swift
var config = ChatClientConfig(apiKey: .init("<# Your API Key Here #>"))
config.applicationGroupIdentifier = "group.x.y.z"

/// ...

let client = ChatClient(config: config)

/// ...
```

Note: in order for this to work correctly, you need to do this in the service extension and in the application.
