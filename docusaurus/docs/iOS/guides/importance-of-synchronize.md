---
title: The Importance of Synchronize
---

## About `synchronize()`

 Controllers are lightweight objects and they only fetch data when needed. When a controller is created, it doesn't fetch local or remote data until it needs it.

`synchronize()` makes sure StreamChat's local database and backend is in sync. It queries the backend for the latest state of the Channel and updates the database. In addition, `synchronize()` call starts actually obversing the Channel for changes, so you will start getting live updates of the changes to the Channel, including it's messages.

If you only need the local data, you can just access it after creation, like so:

```swift
let channelController = chatClient.channelController(for: ChannelId(type: .messaging, id: "general"))
let channel = channelController.channel
let messages = channelController.messages
 ```

In addition, you don't need to call `synchronize()` to be able to call actions on the channel, such as `freezeChannel`:

```swift
let channelController = chatClient.channelController(for: ChannelId(type: .messaging, id: "general"))
channelController.freezeChannel()
```

But as stated in the table above, if the Channel is not created in the backend yet, you'll need to call `synchronize()` first, else the action calls will fail.

Additionally, as with all StreamChat Controllers, `ChannelController` has `state` and a delegate function to observe it's `state`:

```swift
func controller(_ controller: DataController, didChangeState state: DataController.State)
```

You can use this delegate function to show any error states you might see. For more information, see [DataController Overview](404).
