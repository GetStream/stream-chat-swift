---
title: Creating custom SwiftUI views
---

`StreamChat` provides Combine extensions of the controller components. These controllers are `ObservableObject`s and can be used in your own SwiftUI views.

## Using the controller extensions in your `SwiftUI` views

In this section, we will discuss how a list of channels can be shown in your SwiftUI view using the `ObservableObject` of `ChatChannelListController`
Here, `ChannelListView` is a simple SwiftUI view which will show a list of all channels. We will create an `@ObservedObject` property of type `ChatChannelListController.ObservableObject` so that our view updates whenenver the channels are updated. The `ChatChannelListController.ObservableObject` has a `@Published` property `channels`.

```swift
import StreamChat
import StreamChatUI
import SwiftUI

// View definition

struct ChannelListView: View {
    @ObservedObject var channelList: ChatChannelListController.ObservableObject

    init(channelListController: ChatChannelListController) {
        self.channelList = channelListController.observableObject
    }

    var body: some View {
        VStack {
            List(channelList.channels, id: \.self) { channel in
                Text(channel.name)
            }
        }
        .navigationBarTitle("Channels")
        .onAppear { 
            // call `synchronize()` to update the locally cached data.
            channelList.controller.synchronize() 
        }
    }
}
```

Another simple example could be showing the messages of a particular channel in a `SwiftUI` view. This can be done by using the `ObservableObject` of `ChatChannelController`

```swift
struct MessagesView: View {
    @ObservedObject var channelController = ChatClient.shared.channelController(
        for: ChannelId(
            type: .messaging,
            id: "general"
        )
    ).observableObject
    
    var body: some View {
        List(channelController.messages, id: \.self) { message in
            Text(message.text) // Just show the text of the message
        }.onAppear {
            // call `synchronize()` to update the locally cached data.
            channelController.controller.synchronize()
        }
    }
}
```

In this way, the SwiftUI extensions of the Controller objects can be used to build your own SwiftUI views.
