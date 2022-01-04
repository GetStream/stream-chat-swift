---
title: Getting Started
---

This section provides a high-level overview of the SwiftUI components library. It is a great starting point for discovering how to use Stream's SwiftUI components in your app. For a complete, step-by-step guide check out [iOS Chat tutorial](/tutorials/ios-chat/).

## Your First App with Stream Chat

Before starting, make sure you have installed `StreamChatSwiftUI` as explained in the [Installation](./swiftui-overview.md#installation) section.

## Creating the SwiftUI Context Provider Object

The SwiftUI SDK provides a context provider object that allows simple access to functionalities exposed by the SDK, such as branding, presentation logic, icons and the low-level chat client. The first step you would need to start using the SDK is to create the context provider object, called `StreamChat`.

```swift
let apiKeyString = "your_api_key_string"
let config = ChatClientConfig(apiKey: .init(apiKeyString))
let client = ChatClient(config: config)
let streamChat = StreamChat(chatClient: chatClient)
```

It would be best to do this setup when the app starts, for example, in the `AppDelegate`'s `didFinishLaunchingWithOptions` method. Also, be sure to keep a strong reference to the created `StreamChat` instance, for example, as a variable in the `AppDelegate`. This is the minimal setup that is required for the context provider object.

## Creation Options for the `StreamChat` class

In most cases, you will want to customize many different aspects of the SDK. For example, the colors, the icons and the fonts can all be customized via the `StreamChat` class. This branding information is stored in the `Appearance` class, part of the `StreamChat` object. Also, some utility and presentation logic can be injected via the `StreamChat` class, such as date formatting, channel naming, custom CDN and image merging and processing.

### Changing Colors

The colors can be customized via the `ColorPalette` struct, part of the `Appearance` class. To customize a color, instantiate a new `ColorPalette` struct, set the new colors you want to use and use it in the initialization of the `StreamChat` class. For example, let's change the default tint color in all the screens.

```swift
let apiKeyString = "your_api_key_string"
let config = ChatClientConfig(apiKey: .init(apiKeyString))
let client = ChatClient(config: config)

let streamBlue = UIColor(red: 0, green: 108.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)
var colors = ColorPalette()
colors.tintColor = Color(streamBlue)
let appearance = Appearance(colors: colors)

let streamChat = StreamChat(chatClient: chatClient, appearance: appearance)
```

In this way, you can change all the colors used in the SDK. For a complete reference, please visit this [page](../common-content/reference-docs/stream-chat-ui/appearance.color-palette.md).

### Changing Images

All of the images used in the SDK can be replaced with your custom ones. To customize the images, create a new instance of the `Images` class and update the images you want to change. For example, if we're going to change the love reaction, we need to override the corresponding image property.

```swift
let images = Images()
images.reactionLoveBig = UIImage(systemName: "heart.fill")!

let appearance = Appearance(colors: colors, images: images)

let streamChat = StreamChat(chatClient: chatClient, appearance: appearance)
```

The full reference of images can be found [here](../common-content/reference-docs/stream-chat-ui/appearance.images.md).

### Changing Fonts

You can provide your font to match the style of the rest of your app. In the SDK, the default system font is used, with dynamic type support. To keep this support with your custom fonts, please follow Apple's guidelines about scaling fonts [automatically](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically).

The fonts used in the SDK can be customized via the Fonts struct, which is part of the `Appearance` class. So, for example, if we don't want to use the bold footnote font, we can easily override it with our non-bold version.

```swift
var fonts = Fonts()
fonts.footnoteBold = Font.footnote

let appearance = Appearance(colors: colors, fonts: fonts)

let streamChat = StreamChat(chatClient: chatClient, appearance: appearance)
```

Similarly, you can create your own font and replace the corresponding property. The full reference of fonts can be found [here](../common-content/reference-docs/stream-chat-ui/appearance.fonts.md).

### Changing Presentation Logic

In some cases, you might want to change parts of the way the data is displayed in our UI components. For example, you want to change the date formatting, the naming logic of the channels, or use your CDN for storing the images. For cases like this, you should use the `Utils` class, which is part of the `StreamChat` object. For example, if we want to change the way the channel names are displayed in the channel list component, we need to do the following:

```swift
let channelNamer: ChatChannelNamer = { channel, currentUserId in
    "This is our custom name: \(channel.name ?? "no name")"
}
let utils = Utils(channelNamer: channelNamer)

let streamChat = StreamChat(chatClient: chatClient, appearance: appearance, utils: utils)
```

### Accessing Chat Context Functionalities Through Injectable Variables

If you build your own view components and you want to use the chat context providing options, you can do so in a way that's very similar to SwiftUI's environment. You need to define the corresponding keypath of the functionality you need anywhere in your code.

```swift
@Injected(\.chatClient) var chatClient
@Injected(\.fonts) var fonts
@Injected(\.colors) var colors
@Injected(\.images) var images
@Injected(\.utils) var utils
```

### Putting it all Together

Here's the complete code needed to customize different parts of the `StreamChat` class.

```swift
let apiKeyString = "your_api_key_string"
let config = ChatClientConfig(apiKey: .init(apiKeyString))
let client = ChatClient(config: config)
let streamChat = StreamChat(chatClient: chatClient)

var colors = ColorPalette()
colors.tintColor = Color(.streamBlue)

var fonts = Fonts()
fonts.footnoteBold = Font.footnote

let images = Images()
images.reactionLoveBig = UIImage(systemName: "heart.fill")!

let appearance = Appearance(colors: colors, images: images, fonts: fonts)

let channelNamer: ChatChannelNamer = { channel, currentUserId in
    "This is our custom name: \(channel.name ?? "no name")"
}
let utils = Utils(channelNamer: channelNamer)

let streamChat = StreamChat(chatClient: chatClient, appearance: appearance, utils: utils)
```

Please note that these are customizations for branding and utilities.

Please refer to this [page] (../view-customisations) if you want to customize the views themselves and inject your views, please refer to this [page](../view-customizations).
