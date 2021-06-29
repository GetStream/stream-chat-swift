
### `reactionsEnabled`

If users are allowed to add reactions to messages. Enabled by default.

``` swift
public let reactionsEnabled: Bool
```

### `typingEventsEnabled`

Controls if typing indicators are shown. Enabled by default.

``` swift
public let typingEventsEnabled: Bool
```

### `readEventsEnabled`

Controls whether the chat shows how far you’ve read. Enabled by default.

``` swift
public let readEventsEnabled: Bool
```

### `connectEventsEnabled`

Determines if events are fired for connecting and disconnecting to a chat. Enabled by default.

``` swift
public let connectEventsEnabled: Bool
```

### `uploadsEnabled`

Enables uploads.

``` swift
public let uploadsEnabled: Bool
```

### `repliesEnabled`

Enables message thread replies. Enabled by default.

``` swift
public let repliesEnabled: Bool
```

### `searchEnabled`

Controls if messages should be searchable (this is a premium feature). Disabled by default.

``` swift
public let searchEnabled: Bool
```

### `mutesEnabled`

Determines if users are able to mute other users. Enabled by default.

``` swift
public let mutesEnabled: Bool
```

### `urlEnrichmentEnabled`

Determines if URL enrichment enabled to show they as attachments. Enabled by default.

``` swift
public let urlEnrichmentEnabled: Bool
```

### `messageRetention`

A number of days or infinite. Infinite by default.

``` swift
public let messageRetention: String
```

### `maxMessageLength`

The max message length. 5000 by default.

``` swift
public let maxMessageLength: Int
```

### `commands`

An array of commands, e.g. /giphy.

``` swift
public let commands: [Command]
```

### `createdAt`

A channel created date.

``` swift
public let createdAt: Date
```

### `updatedAt`

A channel updated date.

``` swift
public let updatedAt: Date
```

### `flagsEnabled`

Determines if users are able to flag messages. Enabled by default.

``` swift
public var flagsEnabled: Bool 
