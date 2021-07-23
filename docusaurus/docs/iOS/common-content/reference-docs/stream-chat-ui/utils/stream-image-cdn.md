---
title: StreamImageCDN
---

``` swift
open class StreamImageCDN: ImageCDN 
```

## Inheritance

[`ImageCDN`](../image-cdn)

## Initializers

### `init()`

``` swift
public init() 
```

## Properties

### `streamCDNURL`

``` swift
public static var streamCDNURL = "stream-io-cdn.com"
```

## Methods

### `cachingKey(forImage:)`

``` swift
open func cachingKey(forImage url: URL) -> String 
```

### `urlRequest(forImage:)`

``` swift
open func urlRequest(forImage url: URL) -> URLRequest 
```

### `thumbnailURL(originalURL:preferredSize:)`

``` swift
open func thumbnailURL(originalURL: URL, preferredSize: CGSize) -> URL 
```
