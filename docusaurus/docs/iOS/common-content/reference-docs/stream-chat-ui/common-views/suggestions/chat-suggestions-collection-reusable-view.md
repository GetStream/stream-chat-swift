---
title: ChatSuggestionsCollectionReusableView
---

The header reusable view of the suggestion collection view.

``` swift
open class ChatSuggestionsCollectionReusableView: UICollectionReusableView,
    ComponentsProvider 
```

## Inheritance

[`ComponentsProvider`](../../../utils/components-provider), `UICollectionReusableView`

## Properties

### `reuseId`

The reuse identifier of the reusable header view.

``` swift
open class var reuseId: String 
```

### `suggestionsHeader`

The suggestions header view.

``` swift
open lazy var suggestionsHeader: ChatSuggestionsHeaderView 
```
