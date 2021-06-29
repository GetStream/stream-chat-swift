
### `presenceAvatarView`

A view that shows the avatar image

``` swift
open private(set) lazy var presenceAvatarView: _ChatPresenceAvatarView<ExtraData> = components
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `content`

The data this view component shows.

``` swift
open var content: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) 
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
