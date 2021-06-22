---
id: chatsuggestionscollectionreusableview 
title: ChatSuggestionsCollectionReusableView
slug: /ReferenceDocs/Sources/StreamChatUI/CommonViews/Suggestions/chatsuggestionscollectionreusableview
---

The header reusable view of the suggestion collection view.

``` swift
open class _ChatSuggestionsCollectionReusableView<ExtraData: ExtraDataTypes>: UICollectionReusableView,
    ComponentsProvider 
```

## Inheritance

[`ComponentsProvider`](../../Utils/ComponentsProvider), `UICollectionReusableView`

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
