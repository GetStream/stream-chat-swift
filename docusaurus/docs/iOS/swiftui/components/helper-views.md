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

## Changing the Background of the Channel List

You can change the background of the channel list to be any SwiftUI `View` (`Color`, `LinearGradient`, `Image` etc.). In order to do this, you will need to implement the `makeChannelListBackground` in the `ViewFactory`.

```swift
func makeChannelListBackground(colors: ColorPalette) -> some View {
    Color(colors.background)
        .edgesIgnoringSafeArea(.bottom)
}
```

In this method, you receive the `colors` used in the SDK, but you can ignore them if you want to use custom colors that are not setup via the SDK. 

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
    selectedChannel: Binding<ChannelSelectionInfo?>,
    swipedChannelId: Binding<String?>,
    channelDestination: @escaping (ChannelSelectionInfo) -> ChannelDestination,
    onItemTap: @escaping (ChatChannel) -> Void,
    trailingSwipeRightButtonTapped: @escaping (ChatChannel) -> Void,
    trailingSwipeLeftButtonTapped: @escaping (ChatChannel) -> Void,
    leadingSwipeButtonTapped: @escaping (ChatChannel) -> Void
) -> ChatChannelSwipeableListItem<Self> {
    ChatChannelSwipeableListItem(
        factory: self,
        swipedChannelId: swipedChannelId,
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
- `selectedChannel`: binding of the currently selected channel selection info (channel and optional message).
- `swipedChannelId`: optional id of the swiped channel id.
- `channelDestination`: closure that creates the channel destination.
- `onItemTap`: called when a channel list item is tapped.
- `trailingSwipeRightButtonTapped`: called when the right button of the trailing swiped area is tapped.
- `trailingSwipeLeftButtonTapped`: called when the left button of the trailing swiped area is tapped.
- `leadingSwipeButtonTapped`: called when the button of the leading swiped area is tapped.

The last three parameters have no effect if you have specified `EmptyView` for the leading and trailing swipe area of a channel list item. By default, the leading area returns `EmptyView`. In one of the following sections, we will see how these areas can be customized.

## Changing the Divider of the Chat Channel List

It is not only possible to swap the channel list items itself but also to customize the divider between the items. You can do that by implementing `makeChannelListDividerItem` in the `ViewFactory`. The only requisite is that the item you return needs to be a `View`, which offers you all the freedom you need.

The default implementation uses a simple `Divider` and looks like this:

```swift
public func makeChannelListDividerItem() -> some View {
    Divider()
}
```

If you want your list to not have a divider whatsoever, you can simply return an `EmptyView` here.

## Changing the Top Bar

By default, the SwiftUI SDK shows a search bar at the top of the channel list. This component lets you search through messages matching the search term inside the channels. When you tap on a search result, the corresponding channel is opened, automatically scrolling to the searched message.

In order to replace this component with your own (or completely remove it by returning an `EmptyView`), you need to implement the `makeChannelListTopView` method:

```swift
func makeChannelListTopView(
    searchText: Binding<String>
) -> some View {
    SearchBar(text: searchText)
}
```

In this method, a binding of the search text is provided, in case you want to implement your custom search bar.

## Changing the Footer View

You can add a view at the bottom of the channel list. There are two options here - a footer shown when you scroll to the end of the channel list and a sticky footer that's always visible.

To add a footer at the bottom of the channel list, you need to implement the `makeChannelListFooterView` method:

```swift
public func makeChannelListFooterView() -> some View {
    SomeFooterView()
}
```

To add a sticky footer, always visible at the bottom of the channel list, you need to implement the `makeChannelListStickyFooterView` method:

```swift
func makeChannelListStickyFooterView() -> some View {
    SomeStickyFooterView()
}
```

Both methods return an `EmptyView` by default.

Remember to always inject your custom view factory in your view hierarchy:

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomViewFactory.shared)
    }
}
```

## Customizing the Leading and Trailing Areas

When the user swipes to the right, the SDK by default shows two buttons - one for deleting the channel and one for showing more options. You can customize this view by implementing the `makeTrailingSwipeActionsView` in the `ViewFactory`. Please note that the width of this view is fixed. It's up to the integrating code how the available width will be filled.

```swift
public func makeTrailingSwipeActionsView(
    channel: ChatChannel,
    offsetX: CGFloat,
    buttonWidth: CGFloat,
    swipedChannelId: Binding<String?>,
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
    swipedChannelId: Binding<String?>,
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

In both methods, the `swipedChannelId` is provided. This parameter provides binding to the currently swiped channel. You can set this value to nil, in case you want to revert back the channel list item to its original state after performing an action.

Finally, you need to inject your custom view factory in your view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomViewFactory.shared)
    }
}
```