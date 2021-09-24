
### `controller`

`StreamChat`'s controller that observe the currently logged-in user.

``` swift
open var controller: CurrentChatUserController? 
```

### `avatarView`

The view that shows the current user's avatar.

``` swift
open private(set) lazy var avatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `isEnabled`

``` swift
override open var isEnabled: Bool 
```

### `isHighlighted`

``` swift
override open var isHighlighted: Bool 
```

### `isSelected`

``` swift
override open var isSelected: Bool 
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
@objc override open func updateContent() 
```

### `currentUserController(_:didChangeCurrentUser:)`

``` swift
public func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser: EntityChange<CurrentChatUser>
    ) 
