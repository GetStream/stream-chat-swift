---
title: AudioAttachmentPayload
---

Represents a payload for attachments with `.media` type.

``` swift
public struct AudioAttachmentPayload: AttachmentPayload 
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

An attachment type all `MediaAttachmentPayload` instances conform to. Is set to `.audio`.

``` swift
public static let type: AttachmentType = .audio
```

### `title`

A title, usually the name of the audio.

``` swift
public var title: String?
```

### `audioURL`

A link to the audio.

``` swift
public var audioURL: URL
```

### `file`

The audio itself.

``` swift
public var file: AttachmentFile
```

### `extraData`

An extra data.

``` swift
public var extraData: [String: RawJSON]?
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
