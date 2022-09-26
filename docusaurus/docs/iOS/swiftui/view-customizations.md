---
title: View Customizations
---

## Injecting Your Views

The SwiftUI SDK allows complete view swapping of some of its components. This means you can, for example, create your own (different) channel avatar view and inject it in the slot of the default avatar. For most of the views, the SDK doesn't require anything else than the view to conform to the standard SwiftUI `View` protocol and return a view from the `body` variable. You don't need to implement any other lifecycle related methods or additional protocol conformance. However, you have to conform to SwiftUI's `ToolbarContent` protocol for the navigation bar customizations.

### How the View Swapping Works

All the views that allow slots that your implementations can replace are generic over those views. This means that view type erasure (AnyView) is not used. The views contain default implementations, and in general, you don't have to deal with the generics part of the code. Using generics over type erasure allows SwiftUI to compute the diffing of the views faster and more accurately while boosting performance and correctness. With this, your SwiftUI views will not slow down the chat experience.

### View Factory

To abstract away the creation of the views, a protocol called `ViewFactory` is used in the SDK. This protocol defines the swappable views of the chat experience. There are default implementations for all the views used in the SDK. If you want to customize a view, you will need to implement the `ViewFactory`, but you will need to implement only the view you want to swap.

For example, we want to change the view displayed when there are no channels available. First, we need to create our custom view factory. For simplicity, a singleton is used in the code sample, but that's not required if you have a different setup in your project. Then, we override the corresponding view that we want to be replaced.

```swift
class CustomFactory: ViewFactory {

    @Injected(\.chatClient) public var chatClient

    private init() {}

    public static let shared = CustomFactory()

    func makeNoChannelsView() -> some View {
        VStack {
            Text("This is our own custom no channels view.")
        }
    }

}
```

Afterwards, we need to inject the `CustomFactory` in our view. To do this, we pass the newly created factory to the `ChatChannelListView` (or `ChatChannelView` if only that one is used).

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomFactory.shared)
    }
}
```

And that's everything we need to do to provide our own version of some of the views used in the SDK.

### Build Time Improvements

If you are customizing many view slots (over 15) from the SDK, and you have many generics in your codebase, it's good idea to explicitly specify the types of your custom views with `typealias`. This will improve the build time of your project.

```swift
typealias MoreActionsView = MoreChannelActionsView
```

You can find all the associated types we use in the `ViewFactory` [here](https://github.com/GetStream/stream-chat-swiftui/blob/main/Sources/StreamChatSwiftUI/ViewFactory.swift).
