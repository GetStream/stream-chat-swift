
### `avatarView`

A view that shows the avatar image

``` swift
open private(set) lazy var avatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `onlineIndicatorView`

A view indicating whether the user this view represents is online.

``` swift
open private(set) lazy var onlineIndicatorView: UIView = components
        .onlineIndicatorView.init()
        .withoutAutoresizingMaskConstraints
```

The type of `onlineIndicatorView` is UIView & MaskProviding in Components.
Xcode is failing to compile due to `Segmentation fault: 11` when used here.

### `isOnlineIndicatorVisible`

Bool to determine if the indicator should be shown.

``` swift
open var isOnlineIndicatorVisible: Bool = false 
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

### `layoutSubviews()`

``` swift
override open func layoutSubviews() 
```

### `setUpMask(indicatorVisible:)`

Creates space for indicator view in avatar view by masking path provided by the indicator view.

``` swift
open func setUpMask(indicatorVisible: Bool) 
```

#### Parameters

