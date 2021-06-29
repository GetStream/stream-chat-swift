---
title: AttachmentFileType
---

An attachment file type.

``` swift
public enum AttachmentFileType: String, Codable, Equatable, CaseIterable 
```

## Inheritance

`CaseIterable`, `Codable`, `Equatable`, `String`

## Initializers

### `init(mimeType:)`

Init an attachment file type by mime type.

``` swift
public init(mimeType: String) 
```

#### Parameters

  - mimeType: a mime type.

### `init(ext:)`

Init an attachment file type by a file extension.

``` swift
public init(ext: String) 
```

#### Parameters

  - ext: a file extension.

## Enumeration Cases

### `mp4`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `xls`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `generic`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `ppt`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `zip`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `csv`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `gif`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `pdf`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `mov`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `mp3`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `tar`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `png`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `jpeg`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

### `doc`

A file attachment type.

``` swift
case generic, csv, doc, pdf, ppt, tar, xls, zip, mp3, mp4, mov, jpeg, png, gif
```

## Properties

### `mimeType`

Returns a mime type for the file type.

``` swift
public var mimeType: String 
```
