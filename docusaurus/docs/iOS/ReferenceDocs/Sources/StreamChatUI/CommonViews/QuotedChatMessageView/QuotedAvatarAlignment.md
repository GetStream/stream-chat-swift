---
id: quotedavataralignment 
title: QuotedAvatarAlignment
slug: /ReferenceDocs/Sources/StreamChatUI/CommonViews/QuotedChatMessageView/quotedavataralignment
---

The quoted author's avatar position in relation with the text message.
New custom alignments can be added with extensions and by overriding the `QuotedChatMessageView.setAvatarAlignment()`.

``` swift
public struct QuotedAvatarAlignment: RawRepresentable, Equatable 
```

## Inheritance

`Equatable`, `RawRepresentable`

## Initializers

### `init(rawValue:)`

``` swift
public init(rawValue: Int) 
```

## Properties

### `leading`

The avatar will be aligned to the leading, and the message content on the trailing.

``` swift
public static let leading 
```

### `trailing`

The avatar will be aligned to the trailing, and the message content on the leading.

``` swift
public static let trailing 
```

### `rawValue`

``` swift
public let rawValue: Int
```
