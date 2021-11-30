---
title: Channel Header
---

## Customizing the Channel Header

In most cases, you will need to customize the channel header to fit in with the rest of your app. The SwiftUI SDK provides several customization options, starting from small tweaks, to completely providing your own header.

The most simple change you can do is to change the title of the header, while keeping the same look and feel of it. In order to do this, you need to provide your own implementation of the `ChannelNamer` protocol and inject it in the `Utils` class of the `StreamChat` context provider object.

```swift
let channelNamer: ChatChannelNamer = { channel, currentUserId in
    "Custom namer: \(channel.name ?? "no name")"
}
let utils = Utils(channelNamer: channelNamer)
        
let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

Another simple change you can do is to change the tint color of the header. This will change the navigation bar buttons in all of the SDK components. To do this, simple initialize the `StreamChat` object with your preferred tint color.

```swift
var colors = ColorPalette()
colors.tintColor = Color.red
        
let appearance = Appearance(colors: colors)
         
let streamChat = StreamChat(chatClient: chatClient, appearance: appearance)
```

## Creating Your Own hoHeader

In most cases, you will need to customize the navigation bar even further - either by adding branding information, like logo and text, or even additional buttons that will either push a new view, display a modal sheet or an alert.

In order to do this, you will need to perform few steps. First, you need to create your own header, conforming to SwiftUI's `ToolbarContent` protocol. Let's create a header that will show additional button to the right, to do changes to the channel, instead of the default avatar view.

```swift
public struct CustomChatChannelHeader: ToolbarContent {
    @Injected(\.fonts) var fonts
    @Injected(\.utils) var utils
    @Injected(\.colors) var colors
    @Injected(\.chatClient) var chatClient

    private var channelNamer: ChatChannelNamer {
        utils.channelNamer
    }
    
    private var currentUserId: String {
        chatClient.currentUserId ?? ""
    }
    
    public var channel: ChatChannel
    public var onTapTrailing: () -> ()
    
    public var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack {
                Text(channelNamer(channel, currentUserId) ?? "")
                    .font(fonts.bodyBold)
                Text(channel.onlineInfoText(currentUserId: currentUserId))
                    .font(fonts.footnote)
                    .foregroundColor(Color(colors.textLowEmphasis))
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                onTapTrailing()
            } label: {
                Image(systemName: "pencil")
                    .resizable()
            }
        }
    }
}
```

Our custom header implementation exposes an onTapTrailing callback, that will be called when the trailing button is tapped (for example for displaying an edit view). The implementation of this button will be done in a `ViewModifier`, since the `ToolbarContent` can't keep `@State` variables.

The next step is to provide a new implementation of the `ChannelHeaderViewModifier`. In our case, we need to provide handling for the onTapTrailing method from the `CustomChatChannelHeader`. To do this, we will introduce a new `@State` variable in the modifier and change its state to true when the button is tapped.

```swift
struct CustomChannelModifier: ChannelHeaderViewModifier {
    
    var channel: ChatChannel
    
    @State var editShown = false
    
    func body(content: Content) -> some View {
        content.toolbar {
            CustomChatChannelHeader(channel: channel) {
                editShown = true
            }
        }
        .sheet(isPresented: $editShown) {
            Text("Edit View")
        }
    }
    
}
```

The next step we need to do is to create our own custom view factory (or update existing one if you've already created it) to return the newly created channel view modifier. 

```swift
class CustomFactory: ViewFactory {
    
    @Injected(\.chatClient) public var chatClient
    
    private init() {}
    
    public static let shared = CustomFactory()
    
    func makeChannelHeaderViewModifier(for channel: ChatChannel) -> some ChannelHeaderViewModifier {
        CustomChannelModifier(channel: channel)
    }

}
```

Finally, we need to inject the `CustomFactory` in our view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomFactory.shared)
    }
}
```

These are all the steps needed to provide your own navigation header in the chat channel. 

