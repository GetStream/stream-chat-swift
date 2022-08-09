---
title: UIKit Overview
slug: /uikit
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

### Dependencies 

This SDK tries to keep the list of external dependencies to a minimum, these are the dependencies currently used:

#### StreamChatUI

- [Nuke](https://github.com/kean/Nuke) for loading images  
- [SwiftyGif](https://github.com/kirualex/SwiftyGif) for high performance GIF rendering
- [SwiftyMarkdown](https://github.com/SimonFairbairn/SwiftyMarkdown) for markdown rendering
- [DifferenceKit](https://github.com/ra1028/DifferenceKit) for handling diffing updates
- StreamChat, the low-level client to Stream Chat API

#### StreamChat

- [Starscream](https://github.com/daltoniam/Starscream) to handle WebSocket connections


## Installation

To get started integrating Stream Chat in your UIKit iOS app, check our [Integration](../basics/integration) page

:::tip 
To stay up-to-date with our updates and get a detailed breakdown of what's new, subscribe to the releases of [getstream/stream-chat-swift](https://github.com/GetStream/stream-chat-swift/releases) by clicking the "watch" button. You can further tweak your watch preferences and subscribe only to the release events. 
:::