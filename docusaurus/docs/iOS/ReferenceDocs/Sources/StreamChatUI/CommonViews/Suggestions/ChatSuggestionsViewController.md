
A view controller that shows suggestions of commands or mentions.

``` swift
open class _ChatSuggestionsViewController<ExtraData: ExtraDataTypes>: _ViewController,
    ThemeProvider,
    UICollectionViewDelegate 
```

## Inheritance

[`_ViewController`](../_ViewController), [`ThemeProvider`](../../Utils/ThemeProvider), `UICollectionViewDelegate`

## Properties

### `dataSource`

The data provider of the collection view. A custom `UICollectionViewDataSource` can be provided,
by default `ChatMessageComposerSuggestionsCommandDataSource` is used.
A subclass of `ChatMessageComposerSuggestionsCommandDataSource` can also be provided.

``` swift
public var dataSource: UICollectionViewDataSource? 
```

### `numberOfVisibleRows`

The number of visible commands without scrolling.

``` swift
open var numberOfVisibleRows: CGFloat = 4
```

### `bottomAnchorView`

View to which the suggestions should be pinned.
This view should be assigned as soon as instance of this
class is instantiated, because we set observer to
the bottomAnchorView as soon as we compute the height of the
contentSize of the nested collectionView

``` swift
public var bottomAnchorView: UIView?
```

### `didSelectItemAt`

A closure to observer when an item is selected.

``` swift
public var didSelectItemAt: ((Int) -> Void)?
```

### `isPresented`

Property to check if the suggestions view controller is currently presented.

``` swift
public var isPresented: Bool 
```

### `collectionView`

The collection view of the commands.

``` swift
open private(set) lazy var collectionView: _ChatSuggestionsCollectionView<ExtraData> = components
        .suggestionsCollectionView
        .init(layout: components.suggestionsCollectionViewLayout.init())
        .withoutAutoresizingMaskConstraints
```

### `containerView`

The container view where collectionView is embedded.

``` swift
open private(set) lazy var containerView: UIView = UIView().withoutAutoresizingMaskConstraints
```

### `heightConstraints`

The constraints responsible for setting the height of the main view.

``` swift
public lazy var heightConstraints: NSLayoutConstraint 
```

## Methods

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `collectionView(_:didSelectItemAt:)`

``` swift
public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) 
```
