
### `presenceAvatarView`

A view that shows the avatar image and online presence indicator.

``` swift
open private(set) lazy var presenceAvatarView: _ChatPresenceAvatarView<ExtraData> = components
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `content`

The data this view component shows.

``` swift
open var content: _ChatUser<ExtraData.User>? 
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
