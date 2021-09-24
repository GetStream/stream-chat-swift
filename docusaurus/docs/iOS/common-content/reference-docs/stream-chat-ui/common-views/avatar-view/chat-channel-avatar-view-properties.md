
### `presenceAvatarView`

A view that shows the avatar image

``` swift
open private(set) lazy var presenceAvatarView: ChatPresenceAvatarView = components
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `content`

The data this view component shows.

``` swift
open var content: (channel: ChatChannel?, currentUserId: UserId?) 
```

### `imageMerger`

Object responsible for providing functionality of merging images.
Used when creating compound avatars from channel members individual avatars

``` swift
open var imageMerger: ImageMerging 
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `loadAvatar(for:)`

``` swift
open func loadAvatar(for channel: ChatChannel) 
```

### `loadChannelAvatar(from:)`

Loads the avatar from the URL. This function is used when the channel has a non-nil `imageURL`

``` swift
open func loadChannelAvatar(from url: URL) 
```

#### Parameters

  - url: The `imageURL` of the channel

### `loadDirectMessageChannelAvatar(channel:)`

Loads avatar for a directMessageChannel

``` swift
open func loadDirectMessageChannelAvatar(channel: ChatChannel) 
```

#### Parameters

  - channel: The channel

### `loadMergedAvatars(channel:)`

Loads an avatar which is merged (tiled) version of the first four active members of the channel

``` swift
open func loadMergedAvatars(channel: ChatChannel) 
```

#### Parameters

  - channel: The channel

### `loadAvatarsFrom(urls:channelId:completion:)`

Loads avatars for the given URLs

``` swift
open func loadAvatarsFrom(
        urls: [URL?],
        channelId: ChannelId,
        completion: @escaping ([UIImage], ChannelId)
            -> Void
    ) 
```

#### Parameters

  - urls: The avatar urls
  - channelId: The channelId of the channel
  - completion: Completion that gets called with an array of `UIImage`s when all the avatars are loaded

### `createMergedAvatar(from:)`

Creates a merged avatar from the given images

``` swift
open func createMergedAvatar(from avatars: [UIImage]) -> UIImage? 
```

#### Parameters

  - avatars: The individual avatars

#### Returns

The merged avatar

### `lastActiveMembers()`

``` swift
open func lastActiveMembers() -> [ChatChannelMember] 
```

### `loadIntoAvatarImageView(from:placeholder:)`

``` swift
open func loadIntoAvatarImageView(from url: URL?, placeholder: UIImage?) 
