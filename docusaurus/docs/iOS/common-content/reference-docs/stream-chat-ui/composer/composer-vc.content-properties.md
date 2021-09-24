
### `text`

The text of the input text view.

``` swift
public var text: String
```

### `state`

The state of the composer.

``` swift
public let state: ComposerState
```

### `editingMessage`

The editing message if the composer is currently editing a message.

``` swift
public let editingMessage: ChatMessage?
```

### `quotingMessage`

The quoting message if the composer is currently quoting a message.

``` swift
public let quotingMessage: ChatMessage?
```

### `threadMessage`

The thread parent message if the composer is currently replying in a thread.

``` swift
public var threadMessage: ChatMessage?
```

### `attachments`

The attachments of the message.

``` swift
public var attachments: [AnyAttachmentPayload]
```

### `mentionedUsers`

The mentioned users in the message.

``` swift
public var mentionedUsers: Set<ChatUser>
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

A boolean that checks if the composer is replying in a thread

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
public mutating func editMessage(_ message: ChatMessage) 
```

#### Parameters

  - message: The message that the composer will edit.

### `quoteMessage(_:)`

Sets the content state to quoting a message.

``` swift
public mutating func quoteMessage(_ message: ChatMessage) 
```

#### Parameters

