---
title: Channel List Views
---

## Changing the Loading View

While the channels are loaded, a loading view is displayed, with a simple animating activity indicator. If you want to change this view, with your own custom view, you will need to implement the `makeLoadingView` of the `ViewFactory` protocol.

```swift
class CustomFactory: ViewFactory {
    
    @Injected(\.chatClient) public var chatClient
    
    private init() {}
    
    public static let shared = CustomFactory()
    
    func makeLoadingView() -> some View {
        VStack {
            Text("This is custom loading view")
            ProgressView()
        }
    }
}    
```
 
 Afterwards, you will need to inject the newly created `CustomFactory` into our view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomFactory.shared)
    }
}
```

## Changing the No Channels Available View

When there are no channels available, the SDK displays a screen with a button to start a chat. If you want to replace this screen, you will just need to implement the `makeNoChannelsView` in the `ViewFactory`.

```swift
func makeNoChannelsView() -> some View {
    VStack {
        Spacer()
        Text("This is our own custom no channels view.")
        Spacer()
    }
}
```

## Changing the Chat Channel List Item

You can swap the channel list item that is displayed in the channel list with your own implementation. In order to do that, you should implement the `makeChannelListItem` in the `ViewFactory` protocol.

Here's an example on how to do that.

```swift
public func makeChannelListItem(
    currentChannelId: Binding<String?>,
    channel: ChatChannel,
    channelName: String,
    avatar: UIImage,
    onlineIndicatorShown: Bool,
    disabled: Bool,
    selectedChannel: Binding<ChatChannel?>,
    channelDestination: @escaping (ChatChannel) -> ChannelDestination,
    onItemTap: @escaping (ChatChannel) -> Void,
    onDelete: @escaping (ChatChannel) -> Void,
    onMoreTapped: @escaping (ChatChannel) -> Void
) -> CustomChannelListItem<ChannelDestination> {
    CustomChannelListItem(
        currentChannelId: currentChannelId,
        channel: channel,
        channelName: channelName,
        avatar: avatar,
        onlineIndicatorShown: onlineIndicatorShown,
        disabled: disabled,
        selectedChannel: selectedChannel,
        channelDestination: channelDestination,
        onItemTap: onItemTap,
        onDelete: onDelete,
        onMoreTapped: onMoreTapped
    )
}
```