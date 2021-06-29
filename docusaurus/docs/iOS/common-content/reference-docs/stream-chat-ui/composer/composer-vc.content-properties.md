
### `text`

The text of the input text view.

``` swift
public var text: String
```

### `state`

The state of the composer.

``` swift
public var state: ComposerState
```

### `editingMessage`

The editing message if the composer is currently editing a message.

``` swift
public let editingMessage: _ChatMessage<ExtraData>?
```

### `quotingMessage`

The quoting message if the composer is currently quoting a message.

``` swift
public let quotingMessage: _ChatMessage<ExtraData>?
```

### `threadMessage`

The thread parent message if the composer is currently replying in a thread.

``` swift
public let threadMessage: _ChatMessage<ExtraData>?
```

### `attachments`

The attachments of the message.

``` swift
public var attachments: [AnyAttachmentPayload]
```

### `mentionedUsers`

The mentioned users in the message.

``` swift
public var mentionedUsers: Set<_ChatUser<ExtraData.User>>
```

### `command`

The command of the message.

``` swift
public var command: Command?
```

### `isEmpty`

A boolean that checks if the message contains any content.

``` swift
public var isEmpty: Bool 
```

### `isInsideThread`

A boolean that check if the composer is replying in a thread

``` swift
public var isInsideThread: Bool 
```

### `hasCommand`

A boolean that checks if the composer recognised already a command.

``` swift
public var hasCommand: Bool 
```

## Methods

### `clear()`

Resets the current content state and clears the content.

``` swift
public mutating func clear() 
```

### `editMessage(_:)`

Sets the content state to editing a message.

``` swift
public mutating func editMessage(_ message: _ChatMessage<ExtraData>) 
```

#### Parameters

  - message: The message that the composer will edit.

### `quoteMessage(_:)`

Sets the content state to quoting a message.

``` swift
public mutating func quoteMessage(_ message: _ChatMessage<ExtraData>) 
```

#### Parameters

  - message: The message that the composer will quote.

### `threadMessage(_:)`

Sets the content state to replying to a thread message.

``` swift
public mutating func threadMessage(_ message: _ChatMessage<ExtraData>) 
```

#### Parameters

