
### `separatorKind`

The kind identifier of the cell separator view.

``` swift
open class var separatorKind: String 
```

### `separatorHeight`

The height of the cell separator view. This changes the `minimumLineSpacing` to properly display the separator height.
By default it is the hair height, one physical pixel (1 / displayScale). If a value is set, it will change the default.
The changes will apply after the layout it has been invalidated.

``` swift
open var separatorHeight: CGFloat?
```

## Methods

### `prepare()`

``` swift
override open func prepare() 
```

### `invalidateLayout(with:)`

Partly taken from:​ https:​//github.com/Instagram/IGListKit/issues/571\#issuecomment-386960195

``` swift
override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) 
```

### `layoutAttributesForElements(in:)`

``` swift
override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? 
