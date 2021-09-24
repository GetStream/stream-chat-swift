---
title: ChatMessageComposerSuggestionsMentionDataSource
---

``` swift
open class ChatMessageComposerSuggestionsMentionDataSource: NSObject,
    UICollectionViewDataSource,
    ChatUserSearchControllerDelegate 
```

## Inheritance

`ChatUserSearchControllerDelegate`, `NSObject`, `UICollectionViewDataSource`

## Properties

### `collectionView`

The collection view of the mentions.

``` swift
open var collectionView: ChatSuggestionsCollectionView
```

### `searchController`

The search controller to search for mentions.

``` swift
open var searchController: ChatUserSearchController
```

## Methods

### `collectionView(_:viewForSupplementaryElementOfKind:at:)`

``` swift
public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView 
```

### `collectionView(_:numberOfItemsInSection:)`

``` swift
public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int 
```

### `collectionView(_:cellForItemAt:)`

``` swift
public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell 
```

### `controller(_:didChangeUsers:)`

``` swift
public func controller(
        _ controller: ChatUserSearchController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) 
```
