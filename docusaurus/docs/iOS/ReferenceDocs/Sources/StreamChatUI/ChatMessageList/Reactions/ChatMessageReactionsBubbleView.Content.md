
``` swift
public struct Content 
```

## Initializers

### `init(style:reactions:didTapOnReaction:)`

``` swift
public init(
            style: ChatMessageReactionsBubbleStyle,
            reactions: [ChatMessageReactionData],
            didTapOnReaction: @escaping (MessageReactionType) -> Void
        ) 
```

## Properties

### `style`

``` swift
public let style: ChatMessageReactionsBubbleStyle
```

### `reactions`

``` swift
public let reactions: [ChatMessageReactionData]
```

### `didTapOnReaction`

``` swift
public let didTapOnReaction: (MessageReactionType) -> Void
```
