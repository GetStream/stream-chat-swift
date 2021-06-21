---
id: imageattachmentpayload 
title: ImageAttachmentPayload
slug: referencedocs/sources/streamchat/models/attachments/imageattachmentpayload
---

Represents a payload for attachments with `.image` type.

``` swift
public struct ImageAttachmentPayload: AttachmentPayload 
```

## Inheritance

[`AttachmentPayload`](AttachmentPayload), `Decodable`, `Encodable`

## Initializers

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Properties

### `type`

An attachment type all `ImageAttachmentPayload` instances conform to. Is set to `.image`.

``` swift
public static let type: AttachmentType = .image
```

### `title`

A title, usually the name of the image.

``` swift
public let title: String?
```

### `imageURL`

A link to the image.

``` swift
public internal(set) var imageURL: URL
```

### `imagePreviewURL`

A link to the image preview.

``` swift
public let imagePreviewURL: URL
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
