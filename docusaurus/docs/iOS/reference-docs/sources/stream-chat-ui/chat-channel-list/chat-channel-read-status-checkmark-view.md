---
title: ChatChannelReadStatusCheckmarkView
---

A view that shows a read/unread status of the last message in channel.

``` swift
open class ChatChannelReadStatusCheckmarkView: _View, AppearanceProvider, SwiftUIRepresentable 
```

## Inheritance

[`_View`](../common-views/_view.md), [`SwiftUIRepresentable`](../common-views/swift-ui-representable.md), [`AppearanceProvider`](../utils/appearance-provider.md)

## Properties

### `content`

The data this view component shows.

``` swift
open var content: Status = .empty 
```

### `imageView`

The `UIImageView` instance that shows the read/unread status image.

``` swift
open private(set) lazy var imageView = UIImageView().withoutAutoresizingMaskConstraints
```

## Methods

### `tintColorDidChange()`

``` swift
override open func tintColorDidChange() 
```

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
