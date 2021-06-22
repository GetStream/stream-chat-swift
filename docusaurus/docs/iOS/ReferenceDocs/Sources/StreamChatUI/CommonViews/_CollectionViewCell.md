---
id: _collectionviewcell 
title: _CollectionViewCell
slug: /ReferenceDocs/Sources/StreamChatUI/CommonViews/_collectionviewcell
---

Base class for overridable views StreamChatUI provides.
All conformers will have StreamChatUI appearance settings by default.

``` swift
open class _CollectionViewCell: UICollectionViewCell, Customizable 
```

## Inheritance

[`Customizable`](Customizable), `UICollectionViewCell`

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
