---
title: NukeImageProcessor
---

This class provides resizing operations for `UIImage`. It internally uses `Nuke` porcessors to implement operations on images.

``` swift
open class NukeImageProcessor: ImageProcessor 
```

## Inheritance

[`ImageProcessor`](../image-processor)

## Methods

### `crop(image:to:)`

``` swift
open func crop(image: UIImage, to size: CGSize) -> UIImage? 
```

### `scale(image:to:)`

``` swift
open func scale(image: UIImage, to size: CGSize) -> UIImage 
```
