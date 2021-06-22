---
title: ChatSuggestionsHeaderView
---

The header view of the suggestion collection view.

``` swift
open class ChatSuggestionsHeaderView: _View, AppearanceProvider 
```

## Inheritance

[`_View`](../_view), [`AppearanceProvider`](../../utils/appearance-provider)

## Properties

### `commandImageView`

The image icon of the commands header view.

``` swift
open private(set) lazy var commandImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `headerLabel`

The text label of the commands header view.

``` swift
open private(set) lazy var headerLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
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
