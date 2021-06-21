---
id: chatmessagereactionsview.content 
title: ChatMessageReactionsView.Content
--- 

``` swift
public struct Content 
```

## Initializers

### `init(useBigIcons:reactions:didTapOnReaction:)`

``` swift
public init(
            useBigIcons: Bool,
            reactions: [ChatMessageReactionData],
            didTapOnReaction: ((MessageReactionType) -> Void)?
        ) 
```

## Properties

### `useBigIcons`

``` swift
public let useBigIcons: Bool
```

### `reactions`

``` swift
public let reactions: [ChatMessageReactionData]
```

### `didTapOnReaction`

``` swift
public let didTapOnReaction: ((MessageReactionType) -> Void)?
```
