---
id: streamimagecdn 
title: StreamImageCDN
slug: /ReferenceDocs/Sources/StreamChatUI/Utils/streamimagecdn
---

``` swift
public struct StreamImageCDN: ImageCDN 
```

## Inheritance

[`ImageCDN`](ImageCDN)

## Properties

### `streamCDNURL`

``` swift
public static var streamCDNURL = "stream-io-cdn.com"
```

## Methods

### `cachingKey(forImage:)`

``` swift
public func cachingKey(forImage url: URL) -> String 
```

### `thumbnailURL(originalURL:preferredSize:)`

``` swift
public func thumbnailURL(originalURL: URL, preferredSize: CGSize) -> URL 
```
