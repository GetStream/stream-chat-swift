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
    channel: ChatChannel,
    channelName: String,
    avatar: UIImage,
    onlineIndicatorShown: Bool,
    disabled: Bool,
    selectedChannel: Binding<ChatChannel?>,
    swipedChannelId: Binding<String?>,
    channelDestination: @escaping (ChatChannel) -> ChannelDestination,
    onItemTap: @escaping (ChatChannel) -> Void,
    trailingSwipeRightButtonTapped: @escaping (ChatChannel) -> Void,
    trailingSwipeLeftButtonTapped: @escaping (ChatChannel) -> Void,
    leadingSwipeButtonTapped: @escaping (ChatChannel) -> Void
) -> ChatChannelSwipeableListItem<Self> {
    ChatChannelSwipeableListItem(
        factory: self,
        currentChannelId: swipedChannelId,
        channel: channel,
        channelName: channelName,
        avatar: avatar,
        onlineIndicatorShown: onlineIndicatorShown,
        disabled: disabled,
        selectedChannel: selectedChannel,
        channelDestination: channelDestination,
        onItemTap: onItemTap,
        trailingRightButtonTapped: trailingSwipeRightButtonTapped,
        trailingLeftButtonTapped: trailingSwipeLeftButtonTapped,
        leadingSwipeButtonTapped: leadingSwipeButtonTapped
    )
}
```

In the channel list item creation method, you are provided with several parameters needed for constructing the list item. Here's a more detailed description of the parameters list:

- `channel`: the channel being displayed in the list item.
- `channelName`: the display name of the channel.
- `avatar`: the avatar of the channel.
- `onlineIndicatorShown`: whether the online indicator (about last active members) is shown on the avatar.
- `disabled`: whether the user interactions with the channel are disabled. You should use this value while the view is being swiped, in order to avoid clicking the channel list item instead.
- `selectedChannel`: binding of the currently selected channel.
- `swipedChannelId`: optional id of the swiped channel id.
- `channelDestination`: closure that creates the channel destination.
- `onItemTap`: called when a channel list item is tapped.
- `trailingSwipeRightButtonTapped`: called when the right button of the trailing swiped area is tapped.
- `trailingSwipeLeftButtonTapped`: called when the left button of the trailing swiped area is tapped.
- `leadingSwipeButtonTapped`: called when the button of the leading swiped area is tapped.

The last three parameters have no effect if you have specified `EmptyView` for the leading and trailing swipe area of a channel list item. By default, the leading area returns `EmptyView`. In the following section, we will see how these areas can be customized.

## Customizing the Leading and Trailing Areas

When the user swipes to the right, the SDK by default shows two buttons - one for deleting the channel and one for showing more options. You can customize this view by implementing the `makeTrailingSwipeActionsView` in the `ViewFactory`. Please note that the width of this view is fixed. It's up to the integrating code how the available width will be filled.

```swift
public func makeTrailingSwipeActionsView(
    channel: ChatChannel,
    offsetX: CGFloat,
    buttonWidth: CGFloat,
    leftButtonTapped: @escaping (ChatChannel) -> (),
    rightButtonTapped: @escaping (ChatChannel) -> ()
) -> some View {
    CustomTrailingSwipeActionsView(
        channel: channel,
        offsetX: offsetX,
        buttonWidth: buttonWidth,
        leftButtonTapped: leftButtonTapped,
        rightButtonTapped: rightButtonTapped
    )
}
```

In case you want to disable swiping to the right, just return `EmptyView` from the method above.

The leading area can be customized in a similar manner, by implementing the `makeLeadingSwipeActionsView` in the `ViewFactory`. The width in this area is fixed as well.

```swift
func makeLeadingSwipeActionsView(
    channel: ChatChannel,
    offsetX: CGFloat,
    buttonWidth: CGFloat,
    buttonTapped: @escaping (ChatChannel) -> ()
) -> some View {
    HStack {
        ActionItemButton(imageName: "pin.fill") {
            buttonTapped(channel)
        }
        .frame(width: buttonWidth)
        .foregroundColor(Color.white)
        .background(Color.yellow)

        Spacer()
    }
}
```

Finally, you need to inject your custom view factory in your view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomViewFactory.shared)
    }
}
```