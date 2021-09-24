---
title: GiphyAttachmentPayload
---

Represents a payload for attachments with `.giphy` type.

``` swift
public struct GiphyAttachmentPayload: AttachmentPayload 
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

An attachment type all `GiphyAttachmentPayload` instances conform to. Is set to `.giphy`.

``` swift
public static let type: AttachmentType = .giphy
```

### `title`

A  title, usually the search request used to find the gif.

``` swift
public var title: String
```

### `previewURL`

A link to gif file.

``` swift
public var previewURL: URL
```

### `actions`

Actions when gif is not sent yet. (e.g. `Shuffle`)

``` swift
public var actions: [AttachmentAction]
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
