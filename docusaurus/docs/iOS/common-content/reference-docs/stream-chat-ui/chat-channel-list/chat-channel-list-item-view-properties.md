
### `content`

The data this view component shows.

``` swift
public var content: Content? 
```

### `dateFormatter`

The date formatter of the `timestampLabel`

``` swift
public lazy var dateFormatter: DateFormatter 
```

### `mainContainer`

Main container which holds `avatarView` and two horizontal containers `title` and `unreadCount` and
`subtitle` and `timestampLabel`

``` swift
open private(set) lazy var mainContainer: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
```

### `topContainer`

By default contains `title` and `unreadCount`.
This container is embed inside `mainContainer ` and is the one above `bottomContainer`

``` swift
open private(set) lazy var topContainer: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
```

### `bottomContainer`

By default contains `subtitle` and `timestampLabel`.
This container is embed inside `mainContainer ` and is the one below `topContainer`

``` swift
open private(set) lazy var bottomContainer: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
```

### `titleLabel`

The `UILabel` instance showing the channel name.

``` swift
open private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `subtitleLabel`

The `UILabel` instance showing the last message or typing users if any.

``` swift
open private(set) lazy var subtitleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `timestampLabel`

The `UILabel` instance showing the time of the last sent message.

``` swift
open private(set) lazy var timestampLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `avatarView`

The view used to show channels avatar.

``` swift
open private(set) lazy var avatarView: _ChatChannelAvatarView<ExtraData> = components
        .channelAvatarView
        .init()
        .withoutAutoresizingMaskConstraints
```

### `unreadCountView`

The view showing number of unread messages in channel if any.

``` swift
open private(set) lazy var unreadCountView: ChatChannelUnreadCountView = components
        .channelUnreadCountView.init()
        .withoutAutoresizingMaskConstraints
```

### `titleText`

Text of `titleLabel` which contains the channel name.

``` swift
open var titleText: String? 
```

### `subtitleText`

Text of `subtitleLabel` which contains current typing user or the last message in the channel.

``` swift
open var subtitleText: String? 
```

### `timestampText`

Text of `timestampLabel` which contains the time of the last sent message.

``` swift
open var timestampText: String? 
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
