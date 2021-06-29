
### `messageController`

``` swift
public var messageController: _ChatMessageController<ExtraData>!
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
public func toggleReaction(_ reaction: MessageReactionType) 
```

### `messageController(_:didChangeMessage:)`

``` swift
public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) 
