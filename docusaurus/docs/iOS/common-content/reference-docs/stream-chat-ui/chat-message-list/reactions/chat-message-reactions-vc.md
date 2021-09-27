---
title: ChatMessageReactionsVC
---

Controller for the message reactions picker as a list of toggles

``` swift
open class ChatMessageReactionsVC: _ViewController, ThemeProvider, ChatMessageControllerDelegate 
```

## Inheritance

[`_ViewController`](../../../common-views/_view-controller), `ChatMessageControllerDelegate`, [`ThemeProvider`](../../../utils/theme-provider)

## Properties

### `messageController`

``` swift
public var messageController: ChatMessageController!
```

### `reactionsBubble`

``` swift
public private(set) lazy var reactionsBubble = components
        .reactionsBubbleView
        .init()
        .withoutAutoresizingMaskConstraints
```

## Methods

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `toggleReaction(_:)`

``` swift
open func toggleReaction(_ reaction: MessageReactionType) 
```

### `messageController(_:didChangeMessage:)`

``` swift
open func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) 
```
