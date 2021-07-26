---
title: ChatCommandSuggestionCollectionViewCell
---

A view cell that displays a command.

``` swift
open class _ChatCommandSuggestionCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, ComponentsProvider 
```

## Inheritance

[`_CollectionViewCell`](../../../_collection-view-cell), [`ComponentsProvider`](../../../../utils/components-provider)

## Properties

### `reuseId`

``` swift
open class var reuseId: String 
```

### `commandView`

``` swift
public private(set) lazy var commandView = components
        .suggestionsCommandView.init()
        .withoutAutoresizingMaskConstraints
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```
