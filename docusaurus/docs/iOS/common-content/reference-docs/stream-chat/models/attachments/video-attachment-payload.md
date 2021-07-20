---
title: VideoAttachmentPayload
---

Represents a payload for attachments with `.media` type.

``` swift
public struct VideoAttachmentPayload: AttachmentPayload 
```

## Inheritance

[`AttachmentPayload`](../attachment-payload), `Decodable`, `Encodable`

## Initializers

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Properties

### `type`

An attachment type all `MediaAttachmentPayload` instances conform to. Is set to `.video`.

``` swift
public static let type: AttachmentType = .video
```

### `title`

A title, usually the name of the video.

``` swift
public let title: String?
```

### `videoURL`

A link to the video.

``` swift
public internal(set) var videoURL: URL
```

### `file`

The video itself.

``` swift
public let file: AttachmentFile
```

## Methods

### `extraData(ofType:)`

Decodes extra data as an instance of the given type.

``` swift
public func extraData<T: Decodable>(ofType: T.Type = T.self) -> T? 
```

#### Parameters

  - ofType: The type an extra data should be decoded as.

#### Returns

Extra data of the given type or `nil` if decoding fails.

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
