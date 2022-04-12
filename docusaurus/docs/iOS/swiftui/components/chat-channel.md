---
title: Chat Channel View
---

## Chat Channel View Overview

The `ChatChannelView` is a container for the view displayed when a channel is presented. The default implementation consists of a header, a message list and a composer.

In order to customize the header, please refer to [this page](../channel-header). For the message list customizations, you can check the [following page](../message-list), while the composer's documentation can be found [here](../message-composer).

## Directly Showing Channel View

In some cases, you want to show directly the channel view, without having a channel list as the previous screen. Here's an example how to show the channel view as an initial screen, with a predefined channel:

```swift
@main
struct TestStreamSDKApp: App {
    
    @Injected(\.chatClient) var chatClient
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
            
    var body: some Scene {
        WindowGroup {
            ChatChannelView(
                viewFactory: DefaultViewFactory.shared,
                channelController: controller
            )
        }

    }
    
    private var controller: ChatChannelController {
        let controller = chatClient.channelController(
            for: try! ChannelId(cid: "messaging:0D991C91-2"),
           messageOrdering: .topToBottom
        )
        
        return controller
    }
    
}
``` 