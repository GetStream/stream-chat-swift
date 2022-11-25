---
title: ImageCDN
---

ImageCDN is providing set of functions to improve handling of images from CDN.

``` swift
public protocol ImageCDN 
```

## Default Implementations

### `urlRequest(forImage:)`

``` swift
public func urlRequest(forImage url: URL) -> URLRequest 
```

## Requirements

### cachingKey(forImage:​)

Customised (filtered) key for image cache.

``` swift
func cachingKey(forImage url: URL) -> String
```

#### Parameters

  - `imageURL`: URL of the image that should be customised (filtered).

#### Returns

String to be used as an image cache key.

### `urlRequest(forImage:​)`

Prepare and return a `URLRequest` for the given image `URL`
This function can be used to inject custom headers for image loading request.

``` swift
func urlRequest(forImage url: URL) -> URLRequest
```

### thumbnailURL(originalURL:​preferredSize:​)

Enhance image URL with size parameters to get thumbnail

``` swift
func thumbnailURL(originalURL: URL, preferredSize: CGSize) -> URL
```

Use view size in points for `preferredSize`, point to pixel ratio (scale) of the device is applied inside of this function.

#### Parameters

  - `originalURL`: URL of the image to get the thumbnail for.
  - `preferredSize`: The requested thumbnail size.
