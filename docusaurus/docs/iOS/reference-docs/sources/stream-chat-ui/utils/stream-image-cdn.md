---
title: StreamImageCDN
---

``` swift
public struct StreamImageCDN: ImageCDN 
```

## Inheritance

[`ImageCDN`](image-cdn)

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
