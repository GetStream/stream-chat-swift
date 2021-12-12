---
title: Overview
slug: /
---

Building on top of the the Stream Chat API, the Stream Chat iOS component libraries include everything you need to build feature-rich and high-functioning chat user experiences out of the box.

We have a component libraries available for both UIKit and SwiftUI. Each library includes an extensive set of performant and customizable UI components which allow you to get started quickly with little to no plumbing required. The libraries supports:

- Rich media messages
- Reactions
- Threads and quoted replies
- Text input commands (ex: Giphy and @mentions)
- Image and file uploads
- Video playback
- Read state and typing indicators
- Channel and message lists
- Push (APN or Firebase)
- Offline storage
- OSX

## Architecture

StreamChat Swift SDK consists of three separate frameworks:

- [`StreamChatUI`](./uikit) provides a set of reusable and customizable UI components to add chat to your UIKit application.
- [`StreamChatSwiftUI`](./swiftui) provides a set of reusable and customizable UI components to add chat to your SwiftUI application.
- `StreamChat` is the low-level client that provides the main chat functionality including offline storage and optimistic updates. You can use it directly in case you want to build your own UI layer for the chat.

We suggest using either [`StreamChatUI`](./uikit) or [`StreamChatSwiftUI`](./swiftui) for most of our users. Unless your UI is completely different from the common industry standard, you should be able to customize the built-in components to match your needs.

:::note
You can use this library to develop OSX application by using the `StreamChat` framework
:::

### Dependencies

This SDK tries to keep the list of external dependencies to a minimum, these are the dependencies currently used:

#### StreamChatUI

- [Nuke](https://github.com/kean/Nuke) for loading images  
- [SwiftyGif](https://github.com/kirualex/SwiftyGif) for high performance GIF rendering
- StreamChat the low-level client to Stream Chat API

#### StreamChatSwiftUI

- [Nuke](https://github.com/kean/Nuke) for loading images  
- [NukeUI](https://github.com/kean/Nuke) for loading images  
- [Gifu](hhttps://github.com/kaishin/Gifu) for high performance GIF rendering
- StreamChat the low-level client to Stream Chat API

#### StreamChat

- [Starscream](https://github.com/daltoniam/Starscream) to handle WebSocket connections

:::note
Starting **4.6.0**, and in order to improve the developer experience, dependencies are hidden inside our libraries.
(Does not apply to StreamChatSwiftUI's dependencies yet)
:::

## Upgrade and Versioning Strategy

The StreamChat Swift SDK adheres to the [semantic versioning](https://semver.org/) rules. 

- Bug fixes and behavior improvements cause **patch** version bump. 
- New features are shipped with an increased **minor** version. 
- Incompatible changes in the API will cause a **major** version increase.

Occasionally, the SDK can include visual changes (whitespace, color changes, sizing, etc) in minor versions, as we are continuously improving the default look of our UI components. Bumping the major version for such changes would not be practical. 


### How should I specify my dependency version? 

You should either use a fixed version, or an optimitistic operator (a.k.a. squiggly arrow), with **all three versions specified**.

Eg. with CocoaPods:

```ruby 
pod 'StreamChat', '~> 4.0.0'
```

To stay up-to-date with our updates and get a detailed breakdown of what's new, subscribe to the releases of [getstream/stream-chat-swift](https://github.com/GetStream/stream-chat-swift/releases) by clicking the "watch" button. You can further tweak your watch preferences and subscribe only to the release events.

