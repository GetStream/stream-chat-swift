---
title: ChatMessageComposerSuggestionsCommandDataSource
---

``` swift
open class ChatMessageComposerSuggestionsCommandDataSource: NSObject, UICollectionViewDataSource 
```

## Inheritance

`NSObject`, `UICollectionViewDataSource`

## Initializers

### `init(with:collectionView:)`

Data Source Initialiser

``` swift
public init(with commands: [Command], collectionView: ChatSuggestionsCollectionView) 
```

#### Parameters

  - commands: The list of commands.
  - collectionView: The collection view of the commands.

## Properties

### `collectionView`

``` swift
open var collectionView: ChatSuggestionsCollectionView
```

### `commands`

The list of commands.

``` swift
open var commands: [Command]
```

### `components`

The current types to override ui components.

``` swift
open var components: Components 
```

### `appearance`

The current types to override ui components.

``` swift
open var appearance: Appearance 
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
