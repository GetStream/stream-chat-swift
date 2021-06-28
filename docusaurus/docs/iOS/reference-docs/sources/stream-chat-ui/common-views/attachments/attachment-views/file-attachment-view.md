---
title: FileAttachmentView
---

A view that displays the file attachment.

``` swift
open class FileAttachmentView: _View, AppearanceProvider 
```

## Inheritance

[`_View`](../../_view.md), [`AppearanceProvider`](../../../utils/appearance-provider.md)

## Properties

### `height`

``` swift
open var height: CGFloat = 54
```

### `content`

``` swift
public var content: Content? 
```

### `fileNameLabel`

``` swift
public private(set) lazy var fileNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
```

### `fileSizeLabel`

``` swift
public private(set) lazy var fileSizeLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
```

### `fileNameAndSizeStack`

``` swift
public private(set) lazy var fileNameAndSizeStack: ContainerStackView 
```

### `fileIconImageView`

The image view that displays the file icon of the attachment.

``` swift
public private(set) lazy var fileIconImageView = UIImageView()
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
