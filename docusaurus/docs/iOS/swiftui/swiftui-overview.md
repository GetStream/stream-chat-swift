---
title: SwiftUI Overview
slug: /swiftui
---

The SwiftUI SDK is built on top of the `StreamChat` framework, and it's a SwfitUI alternative to the `StreamChatUI` SDK. It's made entirely in SwiftUI, using declarative patterns that will be familiar to developers working with SwiftUI. In addition, the SDK includes an extensive set of performant and customizable UI components which allow you to get started quickly with little to no plumbing required.

## Architecture

The SwiftUI SDK offers three types of components:

- Screens - Easiest to integrate, but offer minor customizations, like branding and text changes.
- Stateful components - Offer more customization options and the possibility to inject custom views. Also relatively simple to integrate if the extension points are suitable for your chat use case. These components come with view models.
- Stateless components - These are the building blocks for the other two types of components. To use them, you would have to provide the state and data. Using these components only make sense if you want to implement a completely custom chat experience.

### Dependencies

This SDK tries to keep the list of external dependencies to a minimum, and these are the dependencies currently used:

#### StreamChatSwiftUI

- [Nuke](https://github.com/kean/Nuke) for loading images
- [NukeUI](https://github.com/kean/NukeUI) for SwiftUI async image loading  
- [Gifu](hhttps://github.com/kaishin/Gifu) for high performance GIF rendering
- StreamChat the low-level client to Stream Chat API

#### StreamChat

- [Starscream](https://github.com/daltoniam/Starscream) to handle WebSocket connections

## Installation

To start integrating Stream Chat in your iOS app, check our [Integration](../basics/integration) page


:::tip
To stay up-to-date with our updates and get a detailed breakdown of what's new, subscribe to the releases of [getstream/stream-chat-swift](https://github.com/GetStream/stream-chat-swiftui/releases) by clicking the "watch" button. You can further tweak your watch preferences and subscribe only to the release events.
:::
