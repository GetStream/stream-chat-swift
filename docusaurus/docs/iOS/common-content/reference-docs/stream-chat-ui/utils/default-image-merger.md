---
title: DefaultImageMerger
---

``` swift
open class DefaultImageMerger: ImageMerging 
```

## Inheritance

[`ImageMerging`](../image-merging)

## Initializers

### `init()`

``` swift
public init() 
```

## Methods

### `merge(images:orientation:)`

``` swift
open func merge(
        images: [UIImage],
        orientation: ImageMergeOrientation
    ) -> UIImage? 
```

### `mergeTopToBottom(images:)`

Merges images in top to bottom fashion

``` swift
open func mergeTopToBottom(images: [UIImage]) -> UIImage? 
```

#### Parameters

  - images: The images

#### Returns

The merged image

### `mergeSideToSide(images:)`

Merges images in top to side to side order (left -\> right)

``` swift
open func mergeSideToSide(images: [UIImage]) -> UIImage? 
```

#### Parameters

  - images: The images

#### Returns

The merged image
