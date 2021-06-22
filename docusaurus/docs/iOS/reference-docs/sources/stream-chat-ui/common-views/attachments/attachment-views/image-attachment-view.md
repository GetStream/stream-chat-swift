---
title: ImageAttachmentView
---

A view that displays the image attachment.

``` swift
open class _ImageAttachmentView<ExtraData: ExtraDataTypes>: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../_view), [`ThemeProvider`](../../../utils/theme-provider)

## Properties

### `width`

``` swift
open var width: CGFloat = 100
```

### `height`

``` swift
open var height: CGFloat = 100
```

### `content`

Local URL of the image preview to show.

``` swift
public var content: URL? 
```

### `imageView`

The image view that displays the image of the attachment.

``` swift
open private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
