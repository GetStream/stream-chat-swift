---
title: ChatSuggestionsCollectionView
---

The collection view of the suggestions view controller.

``` swift
open class ChatSuggestionsCollectionView: UICollectionView,
    ThemeProvider,
    Customizable 
```

## Inheritance

[`Customizable`](../../customizable), [`ThemeProvider`](../../../utils/theme-provider), `UICollectionView`

## Initializers

### `init(layout:)`

``` swift
public required init(layout: UICollectionViewLayout) 
```

### `init?(coder:)`

``` swift
public required init?(coder: NSCoder) 
```

## Methods

### `didMoveToSuperview()`

``` swift
override open func didMoveToSuperview() 
```

### `setUp()`

``` swift
public func setUp() 
```

### `setUpAppearance()`

``` swift
public func setUpAppearance() 
```

### `setUpLayout()`

``` swift
public func setUpLayout() 
```

### `updateContent()`

``` swift
public func updateContent() 
```
