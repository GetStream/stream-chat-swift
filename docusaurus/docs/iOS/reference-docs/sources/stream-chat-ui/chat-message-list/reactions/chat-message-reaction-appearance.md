---
title: ChatMessageReactionAppearance
---

The default `ReactionAppearanceType` implementation without any additional data
which can be used to provide custom icons for message reaction.

``` swift
public struct ChatMessageReactionAppearance: ChatMessageReactionAppearanceType 
```

## Inheritance

[`ChatMessageReactionAppearanceType`](chat-message-reaction-appearance-type)

## Initializers

### `init(smallIcon:largeIcon:)`

``` swift
public init(
        smallIcon: UIImage,
        largeIcon: UIImage
    ) 
```

## Properties

### `smallIcon`

``` swift
public let smallIcon: UIImage
```

### `largeIcon`

``` swift
public let largeIcon: UIImage
```
