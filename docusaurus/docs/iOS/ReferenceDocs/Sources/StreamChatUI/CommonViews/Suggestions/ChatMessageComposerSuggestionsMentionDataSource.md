
``` swift
open class _ChatMessageComposerSuggestionsMentionDataSource<ExtraData: ExtraDataTypes>: NSObject,
    UICollectionViewDataSource,
    _ChatUserSearchControllerDelegate 
```

## Inheritance

`NSObject`, `UICollectionViewDataSource`, `_ChatUserSearchControllerDelegate`

## Properties

### `collectionView`

The collection view of the mentions.

``` swift
open var collectionView: _ChatSuggestionsCollectionView<ExtraData>
```

### `searchController`

The search controller to search for mentions.

``` swift
open var searchController: _ChatUserSearchController<ExtraData>
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
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) 
```
