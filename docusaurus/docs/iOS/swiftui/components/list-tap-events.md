---
title: Handling Channel List Tap Events
---

## Navigation Destination

The SwiftUI SDK comes with default navigation, which can be updated per your needs. For example, you can completely swap the default chat channel view with your own implementation. Alternatively, you can also intercept the on-tap events and provide your own handling.

First, let's see how you can update the screen that is shown when you tap on a channel. In the `ViewFactory` protocol, there's a method called `makeChannelDestination`, which returns a function with `ChannelSelectionInfo` as a parameter and a view as a result. This function tells the `ChatChannelListView` how to create the navigation destination for the channel tap. You need to provide your own implementation with your custom view.  The `ChannelSelectionInfo` type consists of a channel and an optional message. If the message is a not a nil value, you can use it to scroll to a particular message (e.g. in search results or deep linking).

For simplicity, we are creating a custom view which just displays the name of the channel. Next, in our custom factory, we provide a new creation function for the chat channel.

```swift
struct CustomChannelDestination: View {
    
    var channel: ChatChannel
    
    var body: some View {
        VStack {
            Text("This is the channel \(channel.name ?? "")")
        }
    }
    
}

class CustomFactory: ViewFactory {
    
    @Injected(\.chatClient) public var chatClient
    
    private init() {}
    
    public static let shared = CustomFactory()
    
    func makeChannelDestination() -> (ChannelSelectionInfo) -> CustomChannelDestination {
        { selectionInfo in
            CustomChannelDestination(channel: selectionInfo.channel)
        }
    }
}
```

Those are the only two things you need to do in order to change the chat channel view with your own custom implementation.

## Handling Tap Events

In some cases, you don't want to push a screen to the navigation stack. You might want to show it as a modal, or do additional checks (show alerts), before going to the next screen.

For cases like this, you need to provide your own implementation of the `onItemTap` function that is passed when you create the `ChatChannelListView`.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomFactory.shared) { channel in
            print("\(channel.name ?? "") is tapped")
        }
    }
```

You can keep the state in the view container that has the `ChatChannelListView` in its body. Also, you can attach alerts and sheets on the `ChatChannelListView` itself, to customize the tap behaviour.