
### `content`

Content of the cell - `ChatUser` instance from which we take all information.

``` swift
open var content: ChatUser? 
```

### `avatarView`

`_ChatChannelAvatarView` instance which holds photo of user for tagging.

``` swift
open private(set) lazy var avatarView: ChatUserAvatarView = components
        .mentionAvatarView
        .init()
        .withoutAutoresizingMaskConstraints
```

### `usernameLabel`

Title label which shows users whole name.

``` swift
open private(set) lazy var usernameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `usernameTagLabel`

Subtitle label which shows username tag etc. `@user`.

``` swift
open private(set) lazy var usernameTagLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `mentionSymbolImageView`

ImageView which is located at the right part of the cell, showing @ symbol by default.

``` swift
open private(set) lazy var mentionSymbolImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `textContainer`

ContainerStackView which holds username and userTag labels in vertical axis by default.

``` swift
open private(set) lazy var textContainer = ContainerStackView()
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
