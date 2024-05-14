---
title: State Overview
slug: /client
---

Our [low-level client](https://getstream.io/chat/docs/ios-swift/?language=swift) provides the chat state, such as channels, messages, offline storage and optimistic updates. You can use it directly in case you want to build your own UI layer for the chat.

Both our [UIKit](../uikit/getting-started.md) and [SwiftUI](../swiftui/getting-started.md) UI component libraries use the low-level client. This way we are able to share common functionality across both our UI components libraries and increase performance and stability with every release.

The low-level client provides two ways for managing the state and interacting with the Stream API: state layer and controllers. 

## Accessing State with State Layer

The [state layer](state-layer/state-layer-overview.md) is a new and modern way for managing the state. It follows an architecture where we have objects interacting with the Stream API through async functions. These objects are accompanied with state objects that hold the current state.

:::note
This functionality was added in `StreamChat` version 4.56.0.
:::

## Accessing State with Controllers

The `StreamChat` framework comes with [controllers and delegates](controllers/controllers-overview.md) that you can use to build your own views.

Each controller exposes API functionality and supports delegation. Controllers and their delegates are documented here based on the kind of data they control and allow you to observe. You can find examples on how to build your own view as well.
