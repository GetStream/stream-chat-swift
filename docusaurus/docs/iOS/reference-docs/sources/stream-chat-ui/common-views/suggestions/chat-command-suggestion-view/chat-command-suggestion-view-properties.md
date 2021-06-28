
### `content`

The command that the view will display.

``` swift
open var content: Command? 
```

### `commandImageView`

A view that displays the command image icon.

``` swift
open private(set) lazy var commandImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `commandNameLabel`

A view that displays the name of the command.

``` swift
open private(set) lazy var commandNameLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `commandNameSubtitleLabel`

A view that display the command name and the possible arguments.

``` swift
open private(set) lazy var commandNameSubtitleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `textStackView`

A view container that holds the name and subtitle labels.

``` swift
open private(set) lazy var textStackView: UIStackView = UIStackView()
        .withoutAutoresizingMaskConstraints
```

## Methods

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
