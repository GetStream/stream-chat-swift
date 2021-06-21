---
id: quotedchatmessageview.content 
title: QuotedChatMessageView.Content
--- 

The content of the view.

``` swift
public struct Content 
```

## Initializers

### `init(message:avatarAlignment:)`

``` swift
public init(
            message: _ChatMessage<ExtraData>,
            avatarAlignment: QuotedAvatarAlignment
        ) 
```

## Properties

### `message`

The quoted message.

``` swift
public let message: _ChatMessage<ExtraData>
```

### `avatarAlignment`

The avatar position in relation with the text message.

``` swift
public let avatarAlignment: QuotedAvatarAlignment
```
