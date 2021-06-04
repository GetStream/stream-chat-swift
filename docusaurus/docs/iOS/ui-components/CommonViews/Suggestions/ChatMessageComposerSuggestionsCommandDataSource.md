
``` swift
open class _ChatMessageComposerSuggestionsCommandDataSource<ExtraData: ExtraDataTypes>: NSObject, UICollectionViewDataSource 
```

## Inheritance

`NSObject`, `UICollectionViewDataSource`

## Initializers

### `init(with:collectionView:)`

Data Source Initialiser

``` swift
public init(with commands: [Command], collectionView: _ChatSuggestionsCollectionView<ExtraData>) 
```

#### Parameters

  - commands: The list of commands.
  - collectionView: The collection view of the commands.

## Properties

### `collectionView`

``` swift
open var collectionView: _ChatSuggestionsCollectionView<ExtraData>
```

### `commands`

The list of commands.

``` swift
open var commands: [Command]
```

### `components`

The current types to override ui components.

``` swift
open var components: _Components<ExtraData> 
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
