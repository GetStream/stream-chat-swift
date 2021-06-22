---
id: _control 
title: _Control
slug: /ReferenceDocs/Sources/StreamChatUI/CommonViews/_control
---

Base class for overridable views StreamChatUI provides.
All conformers will have StreamChatUI appearance settings by default.

``` swift
open class _Control: UIControl, Customizable 
```

## Inheritance

[`Customizable`](Customizable), `UIControl`

## Methods

### `didMoveToSuperview()`

``` swift
override open func didMoveToSuperview() 
```

### `setUp()`

``` swift
open func setUp() 
```

### `setUpAppearance()`

``` swift
open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
open func setUpLayout() 
```

### `updateContent()`

``` swift
open func updateContent() 
```

### `traitCollectionDidChange(_:)`

``` swift
override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) 
```

### `layoutSubviews()`

``` swift
override open func layoutSubviews() 
```
