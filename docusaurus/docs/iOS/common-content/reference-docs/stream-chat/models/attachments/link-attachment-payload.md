---
title: LinkAttachmentPayload
---

Represents a payload for attachments with `.linkPreview` type.

``` swift
public struct LinkAttachmentPayload: AttachmentPayload 
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

An attachment type all `LinkAttachmentPayload` instances conform to. Is set to `.linkPreview`.

``` swift
public static let type: AttachmentType = .linkPreview
```

### `originalURL`

An original `URL` that was included into the message text and then enriched.

``` swift
public var originalURL: URL
```

### `title`

A title (e.g video name in case of enriched `YouTube` link or song name in case of `Spotify` link).

``` swift
public var title: String?
```

### `text`

A text, usually description of the link content.

``` swift
public var text: String?
```

### `author`

An author, usually the link origin. (e.g. `YouTube`, `Spotify`)

``` swift
public var author: String?
```

### `titleLink`

A link for displaying an attachment.
Can be different from the original link, depends on the enriching rules.

``` swift
public var titleLink: URL?
```

### `assetURL`

An image.

``` swift
public var assetURL: URL?
```

### `previewURL`

A preview image URL.

``` swift
public var previewURL: URL?
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
