---
id: chatmessagereactionsview.itemview.content 
title: ChatMessageReactionsView.ItemView.Content
--- 

``` swift
public struct Content 
```

## Initializers

### `init(useBigIcon:reaction:onTap:)`

``` swift
public init(
            useBigIcon: Bool,
            reaction: ChatMessageReactionData,
            onTap: ((MessageReactionType) -> Void)?
        ) 
```

## Properties

### `useBigIcon`

``` swift
public let useBigIcon: Bool
```

### `reaction`

``` swift
public let reaction: ChatMessageReactionData
```

### `onTap`

``` swift
public var onTap: ((MessageReactionType) -> Void)?
```
