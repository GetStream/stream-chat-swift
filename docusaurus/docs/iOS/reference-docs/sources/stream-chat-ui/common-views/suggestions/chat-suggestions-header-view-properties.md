
### `commandImageView`

The image icon of the commands header view.

``` swift
open private(set) lazy var commandImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `headerLabel`

The text label of the commands header view.

``` swift
open private(set) lazy var headerLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
