---
title: ImageMergeOrientation
---

The orientation to be used for merge the images

``` swift
public enum ImageMergeOrientation 
```

## Enumeration Cases

### `horizontal`

Merge the given images in horizontal orientation.
The width of the resulting images will be the addition of the widths of all the images,
whereas the height of the resulting image will be equal to the max of heights in the images

``` swift
case horizontal
```

### `vertical`

Merge the given images in vertical orientation.
The width of the resulting images will be equal to the max of widths in the images,
whereas the height of the resulting image will be the addition of the heights of all the images

``` swift
case vertical
```
