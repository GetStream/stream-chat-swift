
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

The current types to override UI components.

``` swift
open var components: Components 
```

### `appearance`

The current types to override UI components.

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
