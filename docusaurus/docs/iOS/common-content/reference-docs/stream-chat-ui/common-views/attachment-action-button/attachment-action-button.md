---
title: AttachmentActionButton
---

Button used to take an action on attachment being uploaded.

``` swift
open class AttachmentActionButton: _Button, AppearanceProvider 
```

## Inheritance

[`_Button`](../../_button), [`AppearanceProvider`](../../../utils/appearance-provider)

## Properties

### `content`

The content this button displays

``` swift
open var content: Content? 
```

### `size`

The button size. It's 24x24 by default

``` swift
open var size: CGSize 
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

### `layoutSubviews()`

``` swift
override open func layoutSubviews() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
