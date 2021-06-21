---
id: chatmessagegiphyview 
title: ChatMessageGiphyView
--- 

``` swift
open class _ChatMessageGiphyView<ExtraData: ExtraDataTypes>: _View, ComponentsProvider 
```

## Inheritance

[`_View`](../../CommonViews/_View), [`ComponentsProvider`](../../Utils/ComponentsProvider)

## Properties

### `content`

``` swift
public var content: ChatMessageGiphyAttachment? 
```

### `intrinsicContentSize`

``` swift
override open var intrinsicContentSize: CGSize 
```

### `imageView`

``` swift
public private(set) lazy var imageView = UIImageView().withoutAutoresizingMaskConstraints
```

### `badge`

``` swift
public private(set) lazy var badge = components
        .giphyBadgeView
        .init()
        .withoutAutoresizingMaskConstraints
```

### `loadingIndicator`

``` swift
public private(set) lazy var loadingIndicator = components
        .loadingIndicator
        .init()
        .withoutAutoresizingMaskConstraints
```

### `hasFailed`

``` swift
public private(set) var hasFailed = false
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
