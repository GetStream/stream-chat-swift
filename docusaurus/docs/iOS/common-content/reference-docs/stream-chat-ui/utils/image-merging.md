---
title: ImageMerging
---

``` swift
public protocol ImageMerging 
```

## Requirements

### merge(images:​orientation:​)

Merges the images provided in the array

``` swift
func merge(
        images: [UIImage],
        orientation: ImageMergeOrientation
    ) -> UIImage?
```

#### Parameters

  - images: The images to combine
  - orientation: The orientation to be used for combining the images

#### Returns

A combined image
