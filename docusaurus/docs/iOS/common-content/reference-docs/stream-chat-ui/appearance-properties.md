
### `asObservableObject`

Used to initialize `_Components` as `ObservableObject`.

``` swift
public var asObservableObject: ObservableObject 
```

### `colorPalette`

A color palette to provide basic set of colors for the Views.

``` swift
public var colorPalette 
```

By providing different object or changing individual colors, you can change the look of the views.

### `fonts`

A set of fonts to be used in the Views.

``` swift
public var fonts 
```

By providing different object or changing individual fonts, you can change the look of the views.

### `images`

A set of images to be used.

``` swift
public var images 
```

By providing different object or changing individual images, you can change the look of the views.

### `localizationProvider`

Provider for custom localization which is dependent on App Bundle.

``` swift
public var localizationProvider: (_ key: String, _ table: String) -> String 
```

### `` `default` ``

``` swift
static var `default`: Appearance 
