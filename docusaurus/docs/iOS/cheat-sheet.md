---
title: StreamChat Cheat Sheet
---

This cheat sheet provides additional information to the official [StreamChat SDK documentation](https://getstream.io/chat/docs/introduction/?language=swift) on our website. You can find here more detailed information, richer code snippets, and commentary to the provided solutions.

#### Summary 

* [Chat Client](#chat-client)
    * [Creating a New Instance of Chat Client](#creating-a-new-instance-of-chat-client)
    * [How Many ChatClient Instances Do I Need?](#how-many-chatclient-instances-do-i-need)
* [User](#user)
    * [Setting the current user](#setting-the-current-user)
    * [Logging out](#logging-out)
* [Connection](#connection)
    * [Handling the connection manually](#handling-the-connection-manually)
    * [Observing connection changes](#observing-connection-changes)
* [Channel List](#channel-list)
    * [Getting the Channels with the Current User as Member](#getting-the-channels-with-the-current-user-as-member)
* [Channel](#channel)
    * [Getting Messages in the Channel](#getting-messages-in-the-channel)
    * [Creating a new Channel](#creating-a-new-channel)
    * [Creating a new 1-1 Channel](#creating-a-new-1-1-channel)
* [Messages](#messages)
    * [Sending a Message](#sending-a-message)
    * [Deleting a Message](#deleting-a-message)
    * [Editing a Message](#editing-a-message)
* [Working with Extra Data](#working-with-extra-data)
    * [What is Extra Data](#what-is-extra-data)
    * [Defining Custom Extra Data](#defining-custom-extra-data)
* [Under the Hood](#under-the-hood)

---

Didn't find what you were looking for? Open an [issue in our repo](https://github.com/GetStream/stream-chat-swift/issues) and suggest a new topic!

---

## Chat Client

### Creating a New Instance of Chat Client

There are several basic approaches to creating a `ChatClient` instance.

**In the most simple setup, you can create a singleton instance** of `ChatClient` and access it from everywhere:

```swift
extension ChatClient {
    /// The singleton instance of `ChatClient`
    static let shared: ChatClient = {
        let config = ChatClientConfig(apiKey: APIKey("qk4nn7rpcn75"))
        return ChatClient(config: config, tokenProvider: .closure { chatClient, completion in
            let token = ... // Provide the StreamChat token for the current user
            completion(.success(token))
        })
    }()
}
```

Another approach is to **create `ChatClient` instance only locally and pass it down to the view controller hierarchy**. 

For example:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) Bool {
        let config = ChatClientConfig(apiKey: APIKey("qk4nn7rpcn75"))
        let chatClient = ChatClient(config: config, tokenProvider: .closure { chatClient, completion in
            let token = ... // Provide the StreamChat token for the current user
            completion(.success(token))
        })
        
        let rootViewController = YourMainViewController(chatClient: chatClient)
        
        // your code to make rootViewController visible

        return true
    }
}
```


### How Many `ChatClient` Instances Do I Need?

For the absolute majority of use cases, an app needs one instance of the `Client` object. 

**You need multiple `Client` instances in one app when:**
- You want to simultaneously show content from multiple different chats (with different `AppId` values)
- You want to simultaneously show the same content as seen for different kinds of users. For example, the left window for an admin user, the right window for an anonymous user. In this case, it's recommended to always use `isLocalStorageEnabled = false` configuration.


## User

### Setting the current user

A valid StreamChat `token` is all you need to properly set your current app user as the current user of `ChatClient`. This token can't be created locally and it must be provided by your backend.

`ChatClient` uses `TokenProvider` to fetch the token of the currently logged in user from you. There are several types of `TokenProvider`s you can choose from:

```swift
/// A token provider accepting a closure as a parameter. This is most likely the provider you 
/// want to use in your production app.
chatClient.tokenProvider = .closure { chatClient, completion in 
  let token = ... // Obtain the chat token from your system
  completion(token)
}

/// A token provider for anonymous users. You'd use this provider for situations when no
/// specific user is logged in.
chatClient.tokenProvider = .anonymous

/// A token provider for a guest user with the specific <id> and name.
chatClient.tokenProvider = .guest(userId: <id>, name: "Luke", imageURL: nil)

/// A token provider returning the hardcoded token
chatClient.tokenProvider = .static(<token>)

/// A token provider that can be used for development. Development tokens are not validated by the servers.
chatClient.tokenProvider = .development(userId: <id>)
```

When the currently logged-in user of the app changes, or when you assign a new token provider to `ChatClient`, you should tell `ChatClient` to reload its current user:

```swift
/// Gets a new token from `TokenProvider` and if the new user id differs from the current one, 
/// reloads the data and reconnects with the new user.
chatClient.currentUserController().reloadUserIfNeeded()
```

### Logging out

It's impossible to log out a user because the `Client` instance must always have a user assigned. 

**However, you can simulate this behavior by:**

- **Destroying the current `Client` instance**

You can destroy all references to the `Client` instance once you don't need it. Every `Controller` holds a strong reference to the parent `Client` instance. You can use this to your advantage and have your view controllers holding a strong reference to `Client` via their referenced controllers. Once all view controllers are deallocated, so are the controllers and, finally, the `Client` instance.

- or **Setting the current user as anonymous**
```swift
chatClient.tokenProvider = .anonymous
chatClient.currentUserController().reloadUserIfNeeded()
```


- or **Disconnecting the client**

This method makes the `Client` instance stop receiving any updates from the server. You can later reconnect without having to set the current user again.
```swift
chatClient.connectionController().disconnect()

// when you want to reconnect

chatClient.connectionController().connect { error in 
    if error == nil {
       // connection successful
    }
}
```


## Connection
### Handling the connection manually
If `config.shouldConnectAutomatically` is set to `false` the establishment of a web-socket connection has to be done manually via `connect/disconnect` in `ChatConnectionController`, otherwise this is done automatically in the `CurrentUserController` when setting the current user.

```swift
chatClient.connectionController().connect { error in 
    if error == nil {
       // connection successful
    }
}
// disconnecting
chatClient.connectionController().disconnect()
```

### Observing connection changes

- **Using UIKit and Delegates**

```swift
class LoggedInUserViewController: UIViewController {
    ...
    override func viewDidLoad() {
       super.viewDidLoad()
       chatClient.connectionController.delegate = self
    }
}

extension LoggedInUserViewController: ChatConnectionControllerDelegate {
    func connectionController(_ controller: ChatConnectionController, didUpdateConnectionStatus status: ConnectionStatus) {
        switch status {
        case .connected:
            onlineIndicatorView.tintColor = .green
        case .disconnected, .disconnecting,  .initialized:
            onlineIndicatorView.tintColor = .red
        case .connecting:
            break
        }
    }
}
```

- **Using UIKit and Combine**

```swift
class LoggedInUserViewController: UIViewController {
    
private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
       super.viewDidLoad()

        chatClient
             .connectionController
             .channelsChangesPublisher
             .receive(on: RunLoop.main)
             .sink { [weak self] state in
                // state changed
             }
             .store(in: &cancellables)
    }
}
```

- **Using SwiftUI and Combine**

```swift
struct LoggedInUserView: View {
    @ObservedObject var connection: ChatConnectionController.ObservableObject

    init(connectionController: ChatConnectionController) {
        self.connection = connectionController.observableObject
    }

    var body: some View {
        switch connection.connectionStatus {
         case .connected:
             Text("Connected")
         case .disconnected, .disconnecting:
             Text("Disconnected")
         case .connecting, .initialized:
             Text("Connecting")
         }
        .navigationBarTitle("Logged In User")
    }
}
```

## Channel List

### Getting the Channels with the Current User as Member

- **Using UIKit and Delegates**

```swift
class ChannelListViewController: UIViewController {

    let channelListController = chatClient.channelListController(
       query: ChannelListQuery(filter: .containMembers(userIds: [chatClient.currentUserId]))
    )

    override func viewDidLoad() {
       super.viewDidLoad()
       channelListController.delegate = self

       // update your UI with the cached channels first, for example by calling reloadData() on UITableView
       let locallyAvailableChannels = channelListController.channels

       // call `synchronize()` to update the locally cached data. the updates will be delivered using delegate methods
       channelListController.synchronize()
    }
}

extension ChannelListViewController: ChatChannelListControllerDelegate { 
    func controller(_ controller: ChatChannelListController, didChangeChannels changes: [ListChange<Channel>]) {
        // The list of channels has changed. You can for example animate the changes:

        tableView.beginUpdates()        
        for change in changes {
            switch change {
            case let .insert(_, index: index):
                tableView.insertRows(at: [index], with: .automatic)
            // etc ...
            }
        }        
        tableView.endUpdates()
    }
}
```

- **Using UIKit and Combine**

```swift
class ChannelsViewController: UIViewController {

    let channelListController = chatClient.channelListController(
       query: ChannelListQuery(filter: .containMembers(userIds: [chatClient.currentUserId]))
    )

    private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
       super.viewDidLoad()

       // update your UI with the cached channels first, for example by calling reloadData() on UITableView
       let locallyAvailableChannels = channelListController.channels

       // Observe changes to the list from the publishers
        channelListController
             .channelsChangesPublisher
             .receive(on: RunLoop.main)
             .sink { [weak self] changes in
                // animate the changes to the channel list
             }
             .store(in: &cancellables)

       // call `synchronize()` to update the locally cached data. the updates will be delivered using channelsChangesPublisher
       channelListController.synchronize()
    }
}
```

- **Using SwiftUI**

```swift

// View definition

struct ChannelListView: View {
    @ObservedObject var channelList: ChatChannelListController.ObservableObject

    init(channelListController: ChatChannelListController) {
        self.channelList = channelListController.observableObject
    }

    var body: some View {
        VStack {
            List(channelList.channels, id: \.self) { channel in
                Text(channel.extraData.name ?? "missing channel name")
            }
        }
        .navigationBarTitle("Channels")
        .onAppear { 
            // call `synchronize()` to update the locally cached data.
            channelList.synchronize() 
        }
    }
}

// Usage

let channelListController = chatClient.channelListController(
    query: ChannelListQuery(filter: .containMembers(userIds: [chatClient.currentUserId]))
)

let view = ChannelListView(channelListController: channelListController)
```


## Channel

### Getting Messages in the Channel

- **Using UIKit and Delegates**

```swift
class ChannelViewController: UIViewController {

   let channelController = chatClient.channelController(cid: <id of the channel>)

   override func viewDidLoad() {
       super.viewDidLoad()
       channelController.delegate = self

       // update your UI with the cached messages first, for example by calling reloadData() on UITableView
       let locallyAvailableMessages = channelController.messages

       // call `synchronize()` to update the locally cached data. the updates will be delivered using delegate methods
       channelController.synchronize()
   }
}

extension ChannelViewController: ChatChannelControllerDelegate { 
    func channelController(_ channelController: ChatChannelController, didUpdateMessages changes: [ListChange<ChatMessage>]) {
        // For example, you can animate the changes in UITableView
        tableView.beginUpdates()
        
        for change in changes {
            switch change {
            case let .insert(_, index: index):
                tableView.insertRows(at: [index], with: .automatic)
            case let .move(_, fromIndex: fromIndex, toIndex: toIndex):
                tableView.moveRow(at: fromIndex, to: toIndex)
            case let .update(_, index: index):
                tableView.reloadRows(at: [index], with: .automatic)
            case let .remove(_, index: index):
                tableView.deleteRows(at: [index], with: .automatic)
            }
        }
        
        tableView.endUpdates()
    }
}
```

- **Using UIKit and Combine**

```swift
class ChannelViewController: UIViewController {

   let channelController = chatClient.channelController(cid: <id of the channel>)

   private var cancellables: Set<AnyCancellable> = []

   override func viewDidLoad() {
       super.viewDidLoad()

       // update your UI with the cached messages first, for example by calling reloadData() on UITableView
       let locallyAvailableMessages = channelController.messages

       // Observe changes to the list of messages
        channelListController
             .messagesChangesPublisher
             .receive(on: RunLoop.main)
             .sink { [weak self] changes in
                // animate the changes to the message list
             }
             .store(in: &cancellables)
   }
}
```

- **Using SwiftUI**

```swift

// View definition
struct ChannelView: View {
    @ObservedObject var channelController: ChatChannelController.ObservableObject

    init(channelController: ChatChannelController) {
        self.channelController = channelController.observableObject
    }

    var body: some View {
        VStack {
            List(channelController.messages, id: \.self) { message in
                Text(message.text)
            }
        }
        .navigationBarTitle(channelController.channel.name ?? "Messages")
        .onAppear { 
            // call `synchronize()` to start updating the cached data
            channelController.synchronize() 
        }
    }
}

// Usage
let channelController = chatClient.channelController(cid: <channel id>)
let view = ChannelView(channelController: channelController)

```

### Creating a new Channel

You can create a new channel by creating a `ChannelController` for it and calling `synchronize { error in ... }`. Once the completion block of `synchronize` is called, and the provided `error` is `nil`, the channel creation was successful.

```swift
// A unique identifier of a channel
let id = UUID().uuidString

// A `ChannelId` for the new channel. `ChannelId` is a combination of channel's type and a unique identifier of the channel.
let cid = ChannelId(type: .messaging, id: id)

let controller = chatClient.channelController(
    createChannelWithId: cid, // Assign `cid` for the new channel
    members: [chatClient.currentUserId], // Add users to the new channel
    extraData: .init(name: "My new channel", imageURL: nil) // Set the name for the channel
)

// At this point, the channel does not exist yet, but you can use the `controller` already. 
//
// This is handy for optimistic UI updates. You can already show the chat UI to the user while
// the channel is being created. The message sending UI should be disabled until the `controller`'s state 
// changes to `remoteDataFetched`.
let someViewController = SomeViewController(channelController: controller)

// ... your code to present the view controller

// The channel is created when `synchronize { }` is called:
controller.synchronize { error in
    if error == nil {
        // The channel was successfully created
    }
} 
```

### Creating a new 1-1 Channel

Direct messaging channels derived their `ChannelId` automatically from their members. You can create a new 1-1 channel by creating a `ChannelController` for it and calling `synchronize { error in ... }`. Once the completion block of `synchronize` is called, and the provided `error` is `nil`, the channel creation was successful.

```swift

let newChannelMemberIds: Set<UserId> = [chatClient.currentUserId, someOtherUserId]

let controller = chatClient.channelController(createDirectMessageChannelWith: newChannelMemberIds)

// At this point, the channel does not exist created yet, but you can use the `controller` already. 
//
// This is handy for optimistic UI updates. You can already show the chat UI to the user while
// the channel is being created. The message sending UI should be disabled until the `controller`'s state 
// changes to `remoteDataFetched`. 
// 
// If there are some existing messages between the current user and `someOtherUser`, they will
// be loaded automatically by `controller`.
let someViewController = SomeViewController(channelController: controller)

// ... your code to present the view controller

// The channel is created when `synchronize { }` is called:
controller.synchronize { error in
    if error == nil {
        // The channel was successfully created
    }
} 
```


## Messages

### Sending a Message

Sending a new message to a channel has several phases.

**`Message.localState` phases when sending a message:**

```
                                    ┌──▶  `nil` if success 
  `pendingSend` ──────▶ `sending` ──┤                      
                                    └─▶   `sendingFailed`                                                         
```

This behavior makes it possible to update your UI with the new message immediately without blocking the UI.

```swift
class MyChannelViewController: UIViewController {
    let controller = ChannelController(cid: <id of the channel>)

    func sendMessage(text: String) {
        // This method creates a new message locally, initially with `localState == .pendingSend`
        controller.createNewMessage(text: text)
    }

    // Example handling for Message local state:
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) UITableViewCell { 
        ...
        let message = controller.messages[indexPath.row]
        if message.localState == .pendingSend {
            // show message as pending send

        } else if message.localState == .sendingFailed {
            // show retry button for the message
        }
        ...
    }
}
```



### Deleting a Message

Deleting a message is performed using a `MessageController` created for the given message.

**`Message.localState` phases when deleting a message:**
```
                ┌──▶  `nil` if success 
   `deleting` ──┤                      
                └─▶  `deletingFailed`                                
```

```swift
class MyChannelViewController: UIViewController {
    let controller = ChannelController(cid: <id of the channel>)

    func deleteMessage(message: Message) {
        // Create a `MessageController` for the message you want to delete
        let messageController = controller.client.messageController(
            cid: channelController.channelQuery.cid,
            messageId: message.id
        )

        // Delete the message
        messageController.deleteMessage()
    }

    // Example handling for Message local state:
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) UITableViewCell { 
        ...
        let message = controller.messages[indexPath.row]
        if message.localState == .deleting {
            // show message as being deleted

        } else if message.localState == .deletingFailed {
            // show retry button for deleting the message
        }
        ...
    }
}
```


### Editing a Message

Editing a message has several phases.

**`MessageModel.localState` phases when editing a message:**

```
                                    ┌──▶  `nil` if success 
  `pendingSync` ──────▶ `syncing` ──┤                      
                                    └─▶   `syncingFailed`                                                         
```

This behavior makes it possible to update your UI with the updated message immediately without blocking the UI.

```swift
class MyChannelViewController: UIViewController {
    let controller = ChannelController(cid: <id of the channel>)

    func editMessage(message: ChatMessage, text: String) {
        let messageController = controller.client.messageController(cid: <id of the channel>, messageId: message.id)

        // This method updates a message locally with the `localState == .pendingSync`
        messageController.editMessage(text: text)
    }

    // Example handling for Message local state:
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) UITableViewCell { 
        ...
        let message = controller.messages[indexPath.row]
        if message.localState == .pendingSync {
            // show message as not being synced with the servers

        } else if message.localState == .syncingFailed {
            // show retry button
        }
        ...
    }
}
```

## Working with Extra Data

### What is Extra Data

You can add additional (extra) data to entities in the chat system. For now, you can add extra data to `ChatUser`, `ChatChannel`, and `ChatMessage`.

The extra data types are defined using the `ExtraDataTypes` protocol the `ChatClient` and other types are generic over. Here you can see the protocol declaration including the default extra data types for the mentioned entities:

```swift
public protocol ExtraDataTypes {
    /// An extra data type for `ChatUser`.
    associatedtype User: UserExtraData = NoExtraData
    
    /// An extra data type for `ChatMessage`.
    associatedtype Message: MessageExtraData = NoExtraData
    
    /// An extra data type for `ChatChannel`.
    associatedtype Channel: ChannelExtraData = NoExtraData
    
    /// An extra data type for `ChatMessageReaction`.
    associatedtype MessageReaction: MessageReactionExtraData = NoExtraData
    
    /// An extra data type for `ChatMessageAttachment`.
    associatedtype Attachment: AttachmentExtraData = NoExtraData
}

class _ChatClient<ExtraData: ExtraDataTypes> { ... }

```

To make working with generic types more convenient, we expose several typealiases. This way, generic types' underlying extra data complexity is hidden, while the whole system stays safe at compile-time. 

```swift
/// A convenience typealias for `ChatClient` with the default data types.
public typealias ChatClient = _ChatClient<NoExtraData>

/// A convenience typealias for `ChatUser` with the default data types.
public typealias ChatUser = _ChatUser<NoExtraData>

/// A convenience typealias for `ChatChannel` with the default data types.
public typealias ChatChannel = _Chatchannel<NoExtraData>

...

```

---

⚠️ **Important:** If the name of the type has the `_` prefix, it's not meant to be used directly. You should instead use the convenience typealias without the prefix.

---

### Defining Custom Extra Data

Changing the default extra data types with your custom types is easy and takes a couple of easy steps.

For example, let's say you want to replace the default `NoExtraData` of `ChatChannel` with your custom `NameAndColorExtraData`:

**1. Define your custom Channel extra data type**

Your custom data type must conform to the `ChannelExtraData` protocol. The protocol has two requirements: the type must be codable, and it must expose a static `defaultValue` variable.

```swift
/// Your custom ChatChannel extra data type
struct NameAndColorExtraData: ChannelExtraData {
    
    /// The value used when decoding the custom data type fails.
    static var defaultValue = NameAndColorExtraData(name: "Unknown", colorName: nil)
    
    let name: String
    let colorName: String?
}
```

**2. Use the type in your custom implementation of `ExtraDataTypes`**

```swift
/// Custom implementation of `ExtraDataTypes` with `NameAndColorExtraData`
enum MyCustomExtraData: ExtraDataTypes {
    typealias Channel = NameAndColorExtraData

    // Note: Unless you specify other custom data types, the default data types are used.
}
```

**3. Define the following typealiases in your module**

You should define the convenience typealiases in the module where you use `StreamChat`. You can copy&paste the snippet below, and replace `MyCustomExtraData` with the type defined in step 2.

```swift
import StreamChat

// Change this typealias to your custom data types
typealias CustomExtraDataTypes = MyCustomExtraData // 👈 Your_Custom_Data_Type_Here 👈

typealias ChatClient = _ChatClient<CustomExtraDataTypes>

typealias ChatUser = _ChatUser<CustomExtraDataTypes.User>
typealias CurrentChatUser = _CurrentChatUser<CustomExtraDataTypes.User>
typealias ChatChannel = _ChatChannel<CustomExtraDataTypes> 
typealias ChatChannelRead = _ChatChannelRead<CustomExtraDataTypes>
typealias ChatChannelMember = _ChatChannelMember<CustomExtraDataTypes.User>
typealias ChatMessage = _ChatMessage<CustomExtraDataTypes> 

typealias CurrentChatUserController = _CurrentChatUserController<CustomExtraDataTypes>
typealias ChatChannelListController = _ChatChannelListController<CustomExtraDataTypes>
typealias ChatChannelController = _ChatChannelController<CustomExtraDataTypes>
typealias ChatMessageController = _ChatMessageController<CustomExtraDataTypes>

```

#### **Important**

Extra data is embedded directly to the root object, not nested under any `extraData` object.

So if you have such a Channel object:
```
{
  'id': ....,
  // all other default fields
  'color': 'red'
}
```
You'd use the `MyCustomExtraData` defined above.

## Under the Hood

This section contains additional information about the SDK, which might help you use it best. However, you don't need to know such details for most use cases to use it in your project successfully.

WIP
