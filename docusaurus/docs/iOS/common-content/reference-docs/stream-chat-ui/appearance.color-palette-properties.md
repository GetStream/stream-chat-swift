
### `text`

General textColor, should be something that contrasts great with your `background` Color

``` swift
public var text: UIColor = .streamBlack
```

### `staticColorText`

Static color which should stay the same in dark and light mode, because it's only used as text on small UI Elements
such as `ChatUnreadCountView`, `GiphyBadge` or Commands icon.

``` swift
public var staticColorText: UIColor = .streamWhiteStatic
```

### `subtitleText`

``` swift
public var subtitleText: UIColor = .streamGray
```

### `highlightedColorForColor`

``` swift
public var highlightedColorForColor: (UIColor) -> UIColor 
```

### `disabledColorForColor`

``` swift
public var disabledColorForColor: (UIColor) -> UIColor 
```

### `unselectedColorForColor`

``` swift
public var unselectedColorForColor: (UIColor) -> UIColor 
```

### `background`

General background of the application. Should be something that is in constrast with `text` color.

``` swift
public var background: UIColor = .streamWhiteSnow
```

### `background1`

``` swift
public var background1: UIColor = .streamWhiteSmoke
```

### `background2`

``` swift
public var background2: UIColor = .streamGrayGainsboro
```

### `background3`

``` swift
public var background3: UIColor = .streamOverlay
```

### `background4`

``` swift
public var background4: UIColor = .streamOverlayDark
```

### `background5`

``` swift
public var background5: UIColor = .streamOverlayDarkStatic
```

### `background6`

``` swift
public var background6: UIColor = .streamGrayWhisper
```

### `background7`

``` swift
public var background7: UIColor = .streamDarkGray
```

### `background8`

``` swift
public var background8: UIColor = .streamWhite
```

### `overlayBackground`

``` swift
public var overlayBackground: UIColor = .streamOverlayLight
```

### `popoverBackground`

``` swift
public var popoverBackground: UIColor = .streamWhite
```

### `highlightedBackground`

``` swift
public var highlightedBackground: UIColor = .streamGrayGainsboro
```

### `highlightedAccentBackground`

``` swift
public var highlightedAccentBackground: UIColor = .streamAccentBlue
```

### `highlightedAccentBackground1`

``` swift
public var highlightedAccentBackground1: UIColor = .streamBlueAlice
```

### `shadow`

``` swift
public var shadow: UIColor = .streamModalShadow
```

### `lightBorder`

``` swift
public var lightBorder: UIColor = .streamWhiteSnow
```

### `border`

``` swift
public var border: UIColor = .streamGrayGainsboro
```

### `border2`

``` swift
public var border2: UIColor = .streamGray
```

### `border3`

``` swift
public var border3: UIColor = .streamGrayWhisper
```

### `alert`

``` swift
public var alert: UIColor = .streamAccentRed
```

### `alternativeActiveTint`

``` swift
public var alternativeActiveTint: UIColor = .streamAccentGreen
```

### `inactiveTint`

``` swift
public var inactiveTint: UIColor = .streamGray
```

### `alternativeInactiveTint`

``` swift
public var alternativeInactiveTint: UIColor = .streamGrayGainsboro
