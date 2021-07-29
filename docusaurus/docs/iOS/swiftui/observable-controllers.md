---
title: Observable Controllers
---

## ChatChannelListController

`ChatChannelListController` allows you to observe a list of chat channels based on the provided query and to paginate channels. You can obtain an `ObservableObject` version of this controller by using the `observableObject` property.

```swift
@ObservedObject var chatChannelListController = ChatClient.shared
        .channelListController(query:
                                .init(filter:
                                        .and([.equal("type", to: "messaging")])
                                )
        ).observableObject
```

### Published properties in `ChatChannelListController`

| Property  | Description |
| -------------- | ----------------------- |
| `channels`  | The channels matching the query |

### Example of showing a list of channels in a `SwiftUI` view

```swift
struct ChannelsView: View {
    // Get an observable object to all the channels of type messaging
    @ObservedObject var channelController = ChatClient.shared.channelListController(query: .init(filter: .and([.equal("type", to: "messaging")]))).observableObject
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Messaging Channels")
                        .font(.largeTitle)
                }
                List(channelController.channels, id: \.self) { channel in
                    Text(channel.name ?? channel.cid.id)
                }
            }
            .onAppear(perform: {
                channelController.controller.synchronize()
            })
        }
    }
}
```

## ChannelController

`ChatChannelController` allows you to observe and mutate data for one channel. You can obtain an `ObservableObject` version of this controller by using the `observableObject` property.

```swift
@ObservedObject var chatChannelController = ChatClient.shared.channelController(
        for: ChannelId(
            type: .messaging,
            id: "general"
        )
    ).observableObject
```

### Published properties in `ChatChannelController`

| Property  | Description |
| -------------- | ----------------------- |
| `channel`  |  The channel the controller represents |
| `messages` | The messages related to the channel |
| `typingUsers` | Currently typing users in the channel |

### Example: Typing Indicator View

Let's build a simple `SwiftUI` `View` that shows the currently typing user in the channel.

```swift
struct TypingUserView: View {
    @ObservedObject var channelController = ChatClient.shared
        .channelController(for: .init(type: .messaging, id: "the-id-of-the-channel"))
        .observableObject
    
    var body: some View {
        VStack {
            Text("Typing Status: \(getTypingString())")
        }.onAppear(perform: {
            channelController.controller.synchronize()
        })
    }
    
    func getTypingString() -> String {
        let otherUsersTyping = channelController.channel?.currentlyTypingUsers.filter({ $0.id != channelController.controller.client.currentUserId })
        
        guard let typingUser = otherUsersTyping?.first else {
            return ""
        }
               
        return "\(typingUser.name ?? typingUser.id) is typing ..."
    }
}

```

## ChannelMemberListController

`ChatChannelMemberListController` allows you to observe and mutate data and observing changes for a list of channel members based on the provided query. You can obtain an `ObservableObject` version of this controller by using the `observableObject` property.

```swift
@ObservedObject var memberListController = ChatClient.shared
        .memberListController(query: .init(cid: .init(type: .messaging, id: "id-of-the-channel")))
        .observableObject
```

### Published properties in `ChannelMemberListController`

| Property  | Description |
| -------------- | ----------------------- |
| `members`  |  The channel members |

### Example: Listing Members of a channel

This example uses the `ChatChannelMemberListController`'s `ObservableObject` to fetch all members on the channel `messaging:123`

```swift
struct MembersView: View {
    @ObservedObject var memberListController = ChatClient.shared
        .memberListController(query: .init(cid: .init(type: .messaging, id: "123")))
        .observableObject
    
    var body: some View {
        NavigationView {
            List(memberListController.members, id: \.self) { member in
                Text(member.name ?? member.id)
            }
        }.onAppear(perform: {
            memberListController.controller.synchronize()
        })
    }
}
```

## ChannelMemberController

`ChatChannelMemberController` allows you to observe and mutate data and observing changes of a specific chat member. You can obtain an `ObservableObject` version of this controller by using the `observableObject` property.

```swift
@ObservedObject var memberController = ChatClient.shared
        .memberController(userId: "some-user-id", in: .init(type: .messaging, id: "123"))
        .observableObject
```

### Published properties in `ChannelMemberController`

| Property  | Description |
| -------------- | ----------------------- |
| `member`  |  The member for this controller |
