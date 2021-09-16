---
title: Thread
---

import Digraph  from '../common-content/digraph.jsx'
import SingletonNote from '../common-content/chat-client.md'
import ComponentsNote from '../common-content/components-note.md'
//import ThreadProperties from '../common-content/reference-docs/stream-chat-ui/chat-thread/chat-thread-vc-properties.md'

The `ChatThreadVC` is very similar with the [`ChatChannelVC`](../channel), the difference is that instead of displaying messages, it displays the replies of a message thread. Just like the `ChatChannelVC` it also contains the `ComposerVC` component to create new replies.

The following diagram shows the components hierarchy of `ChatThreadVC`:

<Digraph>{ `
    ChatThreadVC -> ChatThreadHeaderView
    ChatThreadVC -> ChatMessageListVC
    ChatThreadVC -> ChatMessageComposerVC
    ChatThreadHeaderView [href="../thread-header-view"]
    ChatMessageListVC [href="../message-list"]
    ChatMessageComposerVC [href="../message-composer"]
` }</Digraph>

### Overview

- [`ChatThreadHeaderView`](../thread-header-view) is responsible to display the thread information in the `navigationItem.titleView`.
- [`ChatMessageListVC`](../message-list) is the component that handles the rendering of the replies.
- [`ComposerVC`](../message-composer) is the component that handles the creation of new replies.

## Usage
By default, the `ChatThreadVC` is created when you click to see the replies of a message in the `ChatMessageListVC` component. But in case you want to create it programmatically, you can use the following code:

```swift
let cid = "channel-id"
let messageId = "message-id"
let threadVC = ChatThreadVC()
threadVC.channelController = ChatClient.shared.channelController(for: cid)
threadVC.messageController = ChatClient.shared.messageController(
    cid: cid,
    messageId: messageId
)

navigationController?.show(threadVC)
```

<SingletonNote />

## UI Customization

You can customize how the `ChatThreadVC` looks by subclassing it and swap the component in `Components` config:

```swift
Components.default.threadVC = CustomChatThreadVC.self
```

<ComponentsNote />

Just like the `ChatChannelVC`, the `ChatThreadVC` is only responsible for composing the `ChatThreadHeaderView`, `ChatMessageListVC` and `ChatMessageComposerVC` components together. In case you want to customize the rendering of the replies, you should read the [Message List](../message-list) documentation and the [Message](../message) documentation.

## Properties
<!-- <ThreadProperties /> -->
