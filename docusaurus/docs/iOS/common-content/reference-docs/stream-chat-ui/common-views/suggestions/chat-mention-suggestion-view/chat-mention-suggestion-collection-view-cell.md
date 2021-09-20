---
title: ChatMentionSuggestionCollectionViewCell
---

`UICollectionView` subclass which embeds inside `ChatMessageComposerMentionCellView`

``` swift
open class ChatMentionSuggestionCollectionViewCell: _CollectionViewCell, ComponentsProvider 
```

## Inheritance

[`_CollectionViewCell`](../../../_collection-view-cell), [`ComponentsProvider`](../../../../utils/components-provider)

## Properties

### `reuseId`

Reuse identifier for the cell used in `collectionView(cellForItem:​)`

``` swift
open class var reuseId: String 
```

### `mentionView`

Instance of `ChatMessageComposerMentionCellView` which shows information about the mentioned user.

``` swift
open lazy var mentionView: ChatMentionSuggestionView = components
        .suggestionsMentionView.init()
        .withoutAutoresizingMaskConstraints
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `preferredLayoutAttributesFitting(_:)`

``` swift
override open func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes 
```
