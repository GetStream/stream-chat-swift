---
title: ImageCDN
---

ImageCDN is providing set of functions to improve handling of images from CDN.

``` swift
public protocol ImageCDN 
```

## Requirements

### cachingKey(forImage:​)

Customised (filtered) key for image cache.

``` swift
func cachingKey(forImage url: URL) -> String
```

#### Parameters

  - imageURL: URL of the image that should be customised (filtered).

#### Returns

String to be used as an image cache key.

### thumbnailURL(originalURL:​preferredSize:​)

Enhance image URL with size parameters to get thumbnail

``` swift
func thumbnailURL(originalURL: URL, preferredSize: CGSize) -> URL
```

Use view size in points for `preferredSize`, point to pixel ratio (scale) of the device is applied inside of this function.

#### Parameters

  - originalURL: URL of the image to get the thumbnail for.
  - preferredSize: The requested thumbnail size.
