---
title: Working with Messages
---

## Message object
A message is represented by `ChatMessage` model.
Depending on combination of its properties messages appear differently, a screenshot on the left showcases the most common types of messages. A screenshot on the right shows how some of `ChatMessage` properties are reflected in views:

<img src={require("../assets/messages-showcase.png").default} width="40%"/>
<img src={require("../assets/messages-properties.png").default} width="40%" />

## Optimistic updates

Optimistic updates model is applied to messages, meaning that when there is a change to local messages state it is propagated to chat components so it is displayed for users right away and then it's synchronized with backend. In case of synchronization failure users may be prompted to retry the failed action.

<img src={require("../assets/message-failure-resend.png").default} width="30%" />

This makes `LocalMessageState` one of the most important properties in message's lifecycle, because it's used for keeping messages in sync with backend.

## Get a Message by its ID

You can get a single message by its ID:

 ```swift
import StreamChat 
 
/// Use the `ChatClient` to create a
/// `ChatMessageController` with the `ChannelId`. 
let messageController = chatClient.messageController(
    cid: ChannelId(type: .messaging, id: "general"),
    messageId: "message-id" 
) 
 
/// Get the message 
messageController.synchronize { error in 
    // handle possible errors / access message 
    print(error ?? messageController.message!) 
} 
```

## Create a message 

`ComposerVC` is a UI component that handles messages creation:

<img src={require("../assets/composer-ui.png").default} width="50%" />

If you are using your own component for a message composer you can use `ChatChannelController` to create messages:
```swift
let controller = ChatChannelController(
    channelQuery: ChannelQuery(cid: ChannelId(type: .messaging, id: "general")),
    client: client
)
controller.createNewMessage(
    text: "Hello World!",
    pinning: .noExpiration,
    attachments: [image],
    quotedMessageId: quotedMessage.id,
    completion: { result in
        switch result {
        case .success(let messageId):
            print(messageId)
        case .failure(let error):
            print(error)
        }
    }
)
```

More info on [Pinning](pinned-messages) and [Attachments](working-with-attachments) can be found in corresponding guides.

More on [Quoted](#reply-a-message)  messages could be found in this guide below.

## How sending a message works

When `createNewMessage` is called, `ChatChannelController` creates a new message locally and schedules it for send.

Uploading is handled by an internal entity called `MessageSender`. It automatically starts 
uploading when it detects locally cached messages with `.pendingSend` state. 

There is no need to take care of `MessageSender`, it is created and added to the list of background workers by `ChatClient`.

Sending of the message has the following phases:

1. When a message with `.pendingSend` state local state appears in the db, the sender queues it in the sending queue for the channel the message belongs to.
2. The pending messages are send one by one order by their `locallyCreatedAt` value ascending.
3. When the message is being sent, its local state is changed to `.sending`
4. If the operation is successful, the local state of the message is changed to `nil`. If the operation fails, the local state of is changed to `sendingFailed`.

```
                                    ┌──▶  `nil` if success 
  `pendingSend` ──────▶ `sending` ──┤                      
                                    └─▶   `sendingFailed`                                                         
```

This behavior makes it possible to update your UI with the new message immediately without blocking the UI:

```swift
class MyChannelViewController: UIViewController {
    let controller = ChannelController(cid: <#ChannelId#>)

    func sendMessage(text: String) {
        // This method creates a new message locally,
        // initially with `localState == .pendingSend`
        controller.createNewMessage(text: text)
    }

    // Example handling for Message local state:
    func tableView(
        _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell { 
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

:::info

When a message is created `ChannelController` sends *stop typing event* for this channel

:::

## Edit a message

There is an action for editing messages:

<img src={require("../assets/messages-actions.png").default} width="25%" />

When a user is editing a message `ComposerVC` takes the following appearance:

<img src={require("../assets/composer-edit.png").default} width="50%" />

If you use your own implementation for composer view, the same could be done with `ChatMessageController`:

```swift
let messageController = chatClient.messageController(
    cid: channelId,
    messageId: messageId
) 
messageController.editMessage(text: "World Hello!") { error in
    if let error = error {
        print(error)
    }
}
```
Editing a message has several phases:

**`MessageModel.localState` states when editing a message:**

```
                                    ┌──▶  `nil` if success 
  `pendingSync` ──────▶ `syncing` ──┤                      
                                    └─▶   `syncingFailed`                                                         
```

This behavior makes it possible to update your UI with the updated message immediately without blocking the UI:

```swift
class MyChannelViewController: UIViewController {
    let controller = ChannelController(cid: <#ChannelId#>)

    func editMessage(message: ChatMessage, text: String) {
        let messageController = controller.client.messageController(
            cid: <#ChannelId#>,
            messageId: message.id
        )

        // This method updates a message locally
        // with the `localState == .pendingSync`
        messageController.editMessage(text: text)
    }

    // Example handling for Message local state:
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell { 
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

## Delete a message

A message can be deleted with the corresponding action:

<img src={require("../assets/messages-actions.png").default} width="25%" />


When a user deletes a message it will be hidden for all the rest users in conversation, but it will appear for the user who deleted it like this:

  <img src={require("../assets/message-delete.png").default} width="50%" />

In an upcoming version it will become customizable, so it will be possible to hide deleted messages for all participants in a conversation.

Message deletion is handled by `ChatMessageController`:

```swift
let messageController = chatClient.messageController(
    cid: channelId,
    messageId: messageId
) 
messageController.deleteMessage { error in
    if let error = error {
        print(error)
    }
}
```

If the message has `.pendingSend` or `.sendingFailed` state it will be removed locally as it hasn't been sent yet.

If the message has some other local state it should be removed on the backend.
Before the `delete` network call happens the local state is set to `deleting` and based on
the response it becomes either `nil` if request succeeds or `deletingFailed` if request fails.

```
                ┌──▶  `nil` if success 
   `deleting` ──┤                      
                └─▶  `deletingFailed`                                
```

This behavior makes it possible to update your UI with the updated message immediately without blocking the UI:
```swift
class MyChannelViewController: UIViewController {
    let controller = ChannelController(cid: <#ChannelId#>)

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
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell { 
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

## Reply a message

There are two ways of replying a message:
* **Quoted reply**.
  
  In case if `ComposerVC` is used it looks like this during composing, and the resulting message will show both quoted message and the reply itself.
  
  <img src={require("../assets/composer-quoted.png").default} width="50%" />
* **Thread reply**
  
    Initiating a thread reply takes a user into thread details screen and the resulting message will look like a normal message that is placed inside the thread. It is also possible to duplicate it to the parent channel.
  
    <img src={require("../assets/thread-details.png").default} width="35%" />

    A message with thread replies appears like this:

    <img src={require("../assets/thread-reply.png").default} width="35%" />

If you use your own implementation for message composer you can create a **thread reply** for a message with `MessageController`:

```swift
let messageController = chatClient.messageController(
    cid: channelId,
    messageId: "message-id"
)
messageController.createNewReply(
    text: "Thread reply",
    pinning: nil,
    attachments: [],
    showReplyInChannel: true,
    quotedMessageId: nil
)
```

A **quoted reply** can be created like this:
```swift
let controller = ChatChannelController(
    channelQuery: ChannelQuery(cid: ChannelId(type: .messaging, id: "general")),
    client: client
)
channelController.createNewMessage(
    text: "Quoted reply",
    pinning: nil,
    attachments: [],
    quotedMessageId: "quoted-message-id"
)
```