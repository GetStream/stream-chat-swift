---
id: imageprocessors.lateresize 
title: ImageProcessors.LateResize
slug: /ReferenceDocs/Sources/StreamChatUI/Utils/imageprocessors.lateresize
---

Scales an image to a specified size.
The getting of the size is offloaded via closure after the image is loaded.
The View has time to layout and provide non-zero size.

``` swift
public struct LateResize: ImageProcessing 
```

## Inheritance

`ImageProcessing`

## Initializers

### `init(sizeProvider:)`

Initializes the processor with size providing closure.

``` swift
public init(sizeProvider: @escaping () -> CGSize) 
```

#### Parameters

  - sizeProvider: Closure to obtain size after the image is loaded.

## Properties

### `identifier`

``` swift
public var identifier: String 
```

## Methods

### `process(_:)`

``` swift
public func process(_ image: PlatformImage) -> PlatformImage? 
```
