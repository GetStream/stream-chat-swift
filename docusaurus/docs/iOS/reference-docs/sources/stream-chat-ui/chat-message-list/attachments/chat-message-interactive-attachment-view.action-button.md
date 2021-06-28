---
title: ChatMessageInteractiveAttachmentView.ActionButton
---

``` swift
open class ActionButton: _Button, AppearanceProvider 
```

## Inheritance

[`_Button`](../../common-views/_button.md), [`AppearanceProvider`](../../utils/appearance-provider.md)

## Properties

### `content`

``` swift
public var content: AttachmentAction? 
```

### `didTap`

``` swift
public var didTap: (() -> Void)?
```

### `defaultIntrinsicContentSize`

``` swift
public var defaultIntrinsicContentSize 
```

### `intrinsicContentSize`

``` swift
override open var intrinsicContentSize: CGSize 
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `tintColorDidChange()`

``` swift
override open func tintColorDidChange() 
```

### `handleTouchUpInside()`

``` swift
@objc open func handleTouchUpInside() 
```
