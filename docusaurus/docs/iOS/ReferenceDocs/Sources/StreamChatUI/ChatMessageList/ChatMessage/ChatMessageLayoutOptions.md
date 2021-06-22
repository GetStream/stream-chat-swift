---
id: chatmessagelayoutoptions 
title: ChatMessageLayoutOptions
slug: /ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/chatmessagelayoutoptions
---

Describes the layout of base message content view.

``` swift
public struct ChatMessageLayoutOptions: OptionSet, Hashable 
```

## Inheritance

`CustomStringConvertible`, `Hashable`, `OptionSet`

## Initializers

### `init(rawValue:)`

``` swift
public init(rawValue: Int) 
```

## Properties

### `rawValue`

``` swift
public let rawValue: Int
```

### `flipped`

If set all the content will have trailing alignment. By default, the message sent by the current user is flipped.

``` swift
static let flipped 
```

### `bubble`

If set the message content will be wrapped into a bubble.

``` swift
static let bubble 
```

### `continuousBubble`

If set the message bubble will not have a `tail` (rendered by default as a non rounded corner)

``` swift
static let continuousBubble 
```

### `avatarSizePadding`

If set the message content will have an offset (from the `trailing` edge if `flipped` is set otherwise from `leading`)
equal to the avatar size.

``` swift
static let avatarSizePadding 
```

### `avatar`

If set the message author avatar will be shown.

``` swift
static let avatar 
```

### `timestamp`

If set the message timestamp will be shown.

``` swift
static let timestamp 
```

### `authorName`

If set the message author name will be shown in metadata.

``` swift
static let authorName 
```

### `text`

If set the message text content will be shown.

``` swift
static let text 
```

### `quotedMessage`

If set the message quoted by the current message will be shown.

``` swift
static let quotedMessage 
```

### `threadInfo`

If set the message thread replies information will be shown.

``` swift
static let threadInfo 
```

### `errorIndicator`

If set the error indicator will be shown.

``` swift
static let errorIndicator 
```

### `reactions`

If set the reactions added to the message will be shown.

``` swift
static let reactions 
```

### `onlyVisibleForYouIndicator`

If set the indicator saying that the message is visible for current user only will be shown.

``` swift
static let onlyVisibleForYouIndicator 
```

### `description`

Returns all options the current option set consists of separated by `-` character.

``` swift
public var description: String 
```
