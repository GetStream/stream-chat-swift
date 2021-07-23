
### `content`

A content displayed by the view.

``` swift
open var content: Content = .initial 
```

### `player`

A player the view listens to.

``` swift
open weak var player: AVPlayer? 
```

### `loadingIndicator`

A loading indicator that is visible when video is loading.

``` swift
open private(set) lazy var loadingIndicator: ChatLoadingIndicator = components
        .loadingIndicator.init()
        .withoutAutoresizingMaskConstraints
```

### `playPauseButton`

A playback control button.

``` swift
open private(set) lazy var playPauseButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints
```

### `timestampLabel`

A label displaying the current time position.

``` swift
open private(set) lazy var timestampLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `durationLabel`

A label displaying the overall video duration.

``` swift
open private(set) lazy var durationLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
```

### `timeSlider`

A slider used to show a timeline.

``` swift
open private(set) lazy var timeSlider: UISlider = UISlider()
        .withoutAutoresizingMaskConstraints
```

### `rootContainer`

A container for playback button and time labels.

``` swift
open private(set) lazy var rootContainer: ContainerStackView = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
```

## Methods

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `timeSliderDidChange(_:event:)`

Is invoked when time slider changes the value.

``` swift
@objc open func timeSliderDidChange(_ sender: UISlider, event: UIEvent) 
```

### `handleItemDidPlayToEndTime(_:)`

Is invoked when current track reached the end.

``` swift
@objc open func handleItemDidPlayToEndTime(_ notification: NSNotification) 
```

### `handleTapOnPlayPauseButton()`

Is invoked when playback button is touched up inide.

``` swift
@objc open func handleTapOnPlayPauseButton() 
```

### `unsubscribeFromPlayerNotifications(_:)`

Unsubscribes from all notifications.
Is invoked with old player when new player is set or when current view is deallocated.

``` swift
open func unsubscribeFromPlayerNotifications(_ player: AVPlayer?) 
```

### `subscribeToPlayerNotifications()`

Unsubscribes to current player notifications.
Is invoked when new player is set.

``` swift
open func subscribeToPlayerNotifications() 
