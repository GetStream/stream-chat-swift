---
id: fileattachmentpayload 
title: FileAttachmentPayload
slug: /ReferenceDocs/Sources/StreamChat/Models/Attachments/fileattachmentpayload
---

Represents a payload for attachments with `.file` type.

``` swift
public struct FileAttachmentPayload: AttachmentPayload 
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

An attachment type all `FileAttachmentPayload` instances conform to. Is set to `.file`.

``` swift
public static let type: AttachmentType = .file
```

### `title`

A title, usually the name of the file.

``` swift
public let title: String?
```

### `assetURL`

A link to the file.

``` swift
public internal(set) var assetURL: URL
```

### `file`

The file itself.

``` swift
public let file: AttachmentFile
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
