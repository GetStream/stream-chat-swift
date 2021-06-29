---
title: Customizable
---

``` swift
public protocol Customizable 
```

## Default Implementations

### `updateContentIfNeeded()`

If the view is already in the view hierarchy it calls `updateContent()`, otherwise does nothing.

``` swift
func updateContentIfNeeded() 
```

### `updateContentIfNeeded()`

If the view is already loaded it calls `updateContent()`, otherwise does nothing.

``` swift
func updateContentIfNeeded() 
```

## Requirements

### setUp()

Main point of customization for the view functionality.

``` swift
func setUp()
```

**It's called zero or one time(s) during the view's lifetime.** Calling super implementation is required.

### setUpAppearance()

Main point of customization for the view appearance.

``` swift
func setUpAppearance()
```

**It's called multiple times during the view's lifetime.** The default implementation of this method is empty
so calling `super` is usually not needed.

### setUpLayout()

Main point of customization for the view layout.

``` swift
func setUpLayout()
```

**It's called zero or one time(s) during the view's lifetime.** Calling super is recommended but not required
if you provide a complete layout for all subviews.

### updateContent()

Main point of customizing the way the view updates its content.

``` swift
func updateContent()
```

**It's called every time view's content changes.** Calling super is recommended but not required if you update
the content of all subviews of the view.
