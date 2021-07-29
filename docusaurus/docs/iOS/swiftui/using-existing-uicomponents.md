---
title: Using existing UI components
---

import SingletonNote from '../common-content/chat-client.md'
import ComponentsNote from '../common-content/components-note.md'

`StreamChatUI` provides a suite of UI components that work out-of-the-box with `SwiftUI` apps. These UI components can be easily used as SwiftUI `View`s by using the `asView()` method on them.
This method returns a `UIViewControllerRepresentable` or `UIViewRepresentable` depending on whether it is called on a `UIViewController` or a `UIView`.

Below are a few examples of using the existing views in your `SwiftUI` app.

## Using existing views

### Showing channels

You can show the list of channels in your SwiftUI app for the current user by using the `asView()` method of the `ChatChannelListVC`

```swift
import StreamChat
import StreamChatUI
import SwiftUI

struct ContentView: View {    
    var body: some View {
        NavigationView {
            ChatChannelListVC.asView(
                ChatClient
                    .shared
                    .channelListController(
                        query: ChannelListQuery(
                            filter: .containMembers(
                                userIds: [ChatClient.shared.currentUserId!]
                            )
                        )
                    )
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Chats")
        }
    }
}
```

<SingletonNote />

The `asView()` method, when used on a `UIViewController` provided by the SDK, returns a `UIViewControllerRepresentable` that you can use inside your `View` components.

### Showing messages of a channel

Showing the messages screen for a specific channel is very similar too. Just use the `asView()` method on the `ChatMessageListVC` passing in the appropriate `ChannelId`

```swift
struct ContentView: View {
    var body: some View {
        NavigationView {
            ChatMessageListVC.asView(
                ChatClient.shared.channelController(for: .init(type: .messaging, id: "some-channel-id"))
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("General")
        }
    }
}
```

## Customzing the existing views

### Customizing the look of channels

You can customize how the channels are rendered in the list by creating a SwiftUI View that conforms to the `ChatChannelListItemView.SwiftUIView` protocol. In this view, you can access the UI elements of [`ChannelListItemView`](channel-list-item-view.md) and customize them.
Like every component from this library, this component will also follow the [theming](../customization/theming.md) of your application.

```swift
struct MessengerChatChannelListItem: ChatChannelListItemView.SwiftUIView {
    @EnvironmentObject var components: Components.ObservableObject
    @ObservedObject var dataSource: ChatChannelListItemView.ObservedObject<Self>
    
    init(dataSource: _ChatChannelListItemView<NoExtraData>.ObservedObject<Self>) {
        self.dataSource = dataSource
    }
    
    typealias ExtraData = NoExtraData
    
    var body: some View {
        HStack {
            components
                .channelAvatarView
                .asView((dataSource.content?.channel, dataSource.content?.currentUserId))
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 3) {
                Text(dataSource.titleText ?? "")
                    .font(.system(.body))
                Text(dataSource.subtitleText ?? "")
                    .font(.footnote)
                Text(dataSource.timestampText ?? "")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
    }
}
```

In this example, we create a custom `MessengerChatChannelListItem` which conforms to `ChatChannelListItemView.SwiftUIView`
This protocol extends the `SwiftUI.View` protocol and has two requirements:

- `typealias ExtraData = NoExtraData` The type of `ExtraData` that is to be used
- `init(dataSource: )` which provides you with an `ObservedObject` of `ChatChannelListItemView`. You can use the `content` property of this object to access the channel associated with this view.

After this step, use the `MessengerChatChannelListItem` in the components:

```swift
Components.default.channelContentView = ChatChannelListItemView.SwiftUIWrapper<MessengerChatChannelListItem>.self
```

<ComponentsNote />

**Result:**
<img src={require("../assets/swiftui_custom_channel_view.png").default} width="50%"/>

### Customizing channel avatar

The channel avatar component can be customized by creating a SwiftUI `View` that conforms to `ChatChannelAvatarView.SwiftUIView`

```swift
struct CustomChatChannelAvatarView: ChatChannelAvatarView.SwiftUIView {
    typealias ExtraData = NoExtraData

    @ObservedObject var dataSource: ChatChannelAvatarView.ObservedObject<Self>
    
    @EnvironmentObject var appearance: Appearance.ObservableObject
    
    init(dataSource: ChatChannelAvatarView.ObservedObject<Self>) {
        self.dataSource = dataSource
    }

    var body: some View {
        Image(systemName: "person.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipped()
            .mask(Rectangle())
            .background(Color.secondary)
            .cornerRadius(4)
    }
}
```

**Result:**
<img src={require("../assets/swiftui_custom_channel_avatar.png").default} width="50%"/>

### Customizing the look of messages

The component `ChatMessageContentView` along with `ChatMessageLayoutOptionsResolver` is responsible for the appearance of your message. You can customize it by creating your custom SwiftUI `View` and making it conform to `ChatMessageContentView.SwiftUIView` and providing a custom implementation of the component `ChatMessageLayoutOptionsResolver`

```swift
import StreamChat
import StreamChatUI
import SwiftUI

final class MessengerMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(at indexPath: IndexPath, in channel: _ChatChannel<NoExtraData>, with messages: AnyRandomAccessCollection<_ChatMessage<NoExtraData>>, appearance: Appearance) -> ChatMessageLayoutOptions {        
        return [.text]
    }
}

struct MessengerChatMessageContentView: ChatMessageContentView.SwiftUIView {
    @EnvironmentObject var appearance: Appearance.ObservableObject
    @EnvironmentObject var components: Components.ObservableObject
    @ObservedObject var dataSource: ChatMessageContentView.ObservedObject<Self>
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    init(dataSource: _ChatMessageContentView<NoExtraData>.ObservedObject<MessengerChatMessageContentView>) {
        self.dataSource = dataSource
    }
    
    typealias ExtraData = NoExtraData
    
    var body: some View {
        if let message = dataSource.content {
            VStack {
                Text(dateFormatter.string(from: message.createdAt))
                    .font(Font(appearance.fonts.subheadline as CTFont))
                    .foregroundColor(Color(appearance.colorPalette.subtitleText))
                HStack(alignment: .bottom) {
                    if message.isSentByCurrentUser {
                        Spacer()
                    }
                    VStack(alignment: message.isSentByCurrentUser ? .trailing : .leading) {
                        if !message.text.isEmpty {
                            Text(message.text)
                                .foregroundColor(
                                    message.isSentByCurrentUser ? Color(appearance.colorPalette.text) : Color.white
                                )
                                .font(Font(appearance.fonts.body as CTFont))
                                .padding([.bottom, .top], 8)
                                .padding([.leading, .trailing], 12)
                                .background(
                                    message.isSentByCurrentUser ? Color(appearance.colorPalette.background2) : Color.blue
                                )
                                .cornerRadius(18)
                        }
                    }
                    if !message.isSentByCurrentUser {
                        Spacer()
                    }
                }.padding()
            }
            .padding(.bottom, 10)
        }
    }
}
```

Use the above created components:

```swift
components.messageContentView = ChatMessageContentView.SwiftUIWrapper<MessengerChatMessageContentView>.self
components.messageLayoutOptionsResolver = MessengerMessageLayoutOptionsResolver()
```
