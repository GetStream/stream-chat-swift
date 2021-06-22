---
id: attachmentfile 
title: AttachmentFile
slug: /ReferenceDocs/Sources/StreamChat/Models/Attachments/attachmentfile
---

An attachment file description.

``` swift
public struct AttachmentFile: Codable, Hashable 
```

## Inheritance

`Codable`, `Hashable`

## Initializers

### `init(type:size:mimeType:)`

Init an attachment file.

``` swift
public init(type: AttachmentFileType, size: Int64, mimeType: String?) 
```

#### Parameters

  - type: a file type.
  - size: a file size.
  - mimeType: a mime type.

### `init(url:)`

``` swift
public init(url: URL) throws 
```

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Properties

### `type`

An attachment file type (see `AttachmentFileType`).

``` swift
public let type: AttachmentFileType
```

### `size`

A size of the file.

``` swift
public let size: Int64
```

### `mimeType`

A mime type.

``` swift
public let mimeType: String?
```

### `sizeFormatter`

A file size formatter.

``` swift
public static let sizeFormatter 
```

### `sizeString`

A formatted file size.

``` swift
public var sizeString: String 
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```
