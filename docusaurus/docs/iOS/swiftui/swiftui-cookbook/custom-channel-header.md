---
title: Custom Channel Header
description: How to build WhatsApp style header
---

The channel header appears above the message list in a chat view, and it has many different variations across chat apps.

In this example, we will rebuild the one from WhatsApp. The end result will look like this:

![Screenshot of the channel header.](../../assets/whatsapp-header.png)

First, let's create a new file, called `WhatsAppChannelHeader`. This struct will implement the `ToolbarContent` protocol from SwiftUI, which is required for customizing the navigation bar.

```swift
import StreamChat
import StreamChatSwiftUI
import SwiftUI

struct WhatsAppChannelHeader: ToolbarContent {
	var body: some ToolbarContent {
		//TODO: we will provide the implementation here.
	}
}
```

The channel header from above consists of three sections:
- leading section, represented by the back button. This one is added automatically for push navigation, so no additional changes are needed here.
- title section (also called principal placement in SwiftUI), represented by the channel icon and its name and participant info.
- trailing section, represented by the icons for starting audio and video calls.

### Principal section

First, let's implement the principal section. If you take a closer look at the UI, you will notice that it has two columns:
- the channel icon.
- the channel info, which in turn has two rows.
Therefore, we will need an `HStack` for the columns, and a `VStack` for the title rows.

For the channel icon, we can use the `ChannelAvatarView` from our SwiftUI SDK as a building block. You can easily provide your custom implementation if you look for a different UI.

The `ChannelAvatarView` needs an `avatar`, which is the actual image that will be displayed. To fetch this image, you can use our `ChannelHeaderLoader`, which is an observable object that will trigger view updates whenever the image is available. Additionally, we will need few other objects from the SwiftUI SDK, for getting the user info, fonts, colors and utilities. To use these, add the following lines at the top of your struct:

```swift
@ObservedObject private var channelHeaderLoader = InjectedValues[\.utils].channelHeaderLoader

@Injected(\.chatClient) var chatClient
@Injected(\.utils) var utils
@Injected(\.fonts) var fonts
@Injected(\.colors) var colors
```

The state for the channel will be passed as a parameter to this toolbar content, so we should add it as a variable as well.

```swift
var channel: ChatChannel
```

Next, we will add few computed variables, that will be used for setting up the channel name and the subtitle.

```swift
private var currentUserId: String {
    chatClient.currentUserId ?? ""
}

private var channelNamer: ChatChannelNamer {
    utils.channelNamer
}

private var channelSubtitle: String {
    if channel.memberCount <= 2 {
        return channel.onlineInfoText(currentUserId: currentUserId)
    } else {
        return channel
            .lastActiveMembers
            .map { $0.name ?? $0.id }
            .joined(separator: ", ")
    }
}
```

Finally, we can add the `ToolbarItem` itself, with the placement of `.principal`. Here's the implementation that uses the things we have defined so far. Put this code in the body of the `ToolbarContent`, instead of the "TODO" we have added before.

```swift
ToolbarItem(placement: .principal) {
    HStack {
        ChannelAvatarView(
            avatar: channelHeaderLoader.image(for: channel),
            showOnlineIndicator: false,
            size: CGSize(width: 36, height: 36)
        )
        VStack(alignment: .leading) {
            Text(channelNamer(channel, currentUserId) ?? "")
                .font(fonts.bodyBold)
            Text(channelSubtitle)
                .font(fonts.caption1)
                .foregroundColor(Color(colors.textLowEmphasis))
        }
    }
}
```

### Trailing Section

Next, let's add the trailing section, which will have two buttons in a horizontal stack, for video and audio calling.

```swift
ToolbarItem(placement: .topBarTrailing) {
    HStack {
        Button(action: {
            print("tapped on video")
        }, label: {
            Image(systemName: "video")
        })
        Button(action: {
            print("tapped on audio")
        }, label: {
            Image(systemName: "phone")
        })
    }
}
```

Integrating audio and video calling is outside the scope of this cookbook. If you are interested in integrating our `StreamVideo` SDK for audio and video calling, please check our [docs](https://getstream.io/video/docs/ios/).

Here's the full implementation of the toolbar content for cross-checking.

```swift
struct WhatsAppChannelHeader: ToolbarContent {
    
    @ObservedObject private var channelHeaderLoader = InjectedValues[\.utils].channelHeaderLoader
    
    @Injected(\.chatClient) var chatClient
    @Injected(\.utils) var utils
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    
    var channel: ChatChannel
    
    private var currentUserId: String {
        chatClient.currentUserId ?? ""
    }
    
    private var channelNamer: ChatChannelNamer {
        utils.channelNamer
    }
    
    private var channelSubtitle: String {
        if channel.memberCount <= 2 {
            return channel.onlineInfoText(currentUserId: currentUserId)
        } else {
            return channel
                .lastActiveMembers
                .map { $0.name ?? $0.id }
                .joined(separator: ", ")
        }
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack {
                ChannelAvatarView(
                    avatar: channelHeaderLoader.image(for: channel),
                    showOnlineIndicator: false,
                    size: CGSize(width: 36, height: 36)
                )
                VStack(alignment: .leading) {
                    Text(channelNamer(channel, currentUserId) ?? "")
                        .font(fonts.bodyBold)
                    Text(channelSubtitle)
                        .font(fonts.caption1)
                        .foregroundColor(Color(colors.textLowEmphasis))
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                Button(action: {
                    print("tapped on video")
                }, label: {
                    Image(systemName: "video")
                })
                Button(action: {
                    print("tapped on audio")
                }, label: {
                    Image(systemName: "phone")
                })
            }
        }
    }
}
```

### Channel Header Modifier

The next step would be to create a channel header view modifier, which would be injected into our SwiftUI SDK.

```swift
struct WhatsAppChannelHeaderModifier: ChatChannelHeaderViewModifier {
    
    let channel: ChatChannel
    
    func body(content: Content) -> some View {
        content.toolbar {
            WhatsAppChannelHeader(channel: channel)
        }
    }
}
```

Finally, we need to provide this modifier to the SDK, which will use it instead of the default one. For this, create a new file called `CustomViewFactory` and implement the `makeChannelHeaderViewModifier` from the `ViewFactory` protocol.

```swift
import StreamChat
import StreamChatSwiftUI
import SwiftUI

class CustomViewFactory: ViewFactory {

    @Injected(\.chatClient) public var chatClient

    func makeChannelHeaderViewModifier(for channel: ChatChannel) -> some ChatChannelHeaderViewModifier {
        WhatsAppChannelHeaderModifier(channel: channel)
    }
}
```

Depending on which components you use, you should provide this view factory instead of the default one. For example, if you are using a `ChatChannelListView`, you can pass it in the creation process.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomViewFactory())
    }
}
```

If you run your app now, you should see the updated channel header, as shown on the screenshot.

![Screenshot of the channel header.](../../assets/whatsapp-header.png)

## Summary

In this cookbook, you learnt how to implement your own version of the channel view header, using the `ToolbarContent` API from SwiftUI. We have also shown you how to integrate it with our SwiftUI SDK.

As a next step, you can explore other parts of our cookbook, where we build many interesting customizations. Furthermore, for a complete social experience, we recommend looking into our [Video SDK](https://getstream.io/video/docs/ios/).