---
title: ContainerStackView
---

A view that works similar to a `UIStackView` but in a more simpler and flexible way.
The aim of this view is to make UI customizability easier in the SDK.

``` swift
public class ContainerStackView: UIView 
```

## Inheritance

`UIView`

## Initializers

### `init(axis:alignment:spacing:distribution:arrangedSubviews:)`

Creates the container with predefined configuration and initial arranged subviews.

``` swift
public convenience init(
        axis: NSLayoutConstraint.Axis = .horizontal,
        alignment: Alignment = .fill,
        spacing: Spacing = .auto,
        distribution: Distribution = .natural,
        arrangedSubviews: [UIView] = []
    ) 
```

#### Parameters

  - axis: The axis where the arranged subviews are rendered.
  - alignment: The alignment of the arranged subviews perpendicular to the container’s axis.
  - spacing: The spacing between each arranged subview.
  - distribution: The distribution of the arranged subviews along the container’s axis.
  - arrangedSubviews: The initial arranged subviews.

### `init(frame:)`

``` swift
override public init(frame: CGRect) 
```

## Properties

### `distribution`

The distribution of the arranged subviews along the container’s axis.

``` swift
public var distribution: Distribution = .natural 
```

### `alignment`

The alignment of the arranged subviews perpendicular to the container’s axis.

``` swift
public var alignment: Alignment = .fill 
```

### `axis`

The axis where the arranged subviews are rendered.

``` swift
public var axis: NSLayoutConstraint.Axis = .horizontal
```

### `spacing`

The spacing between each arranged subview.

``` swift
public var spacing: Spacing = .auto 
```

### `isLayoutMarginsRelativeArrangement`

A Boolean value that determines whether the container stack view
lays out its arranged subviews relative to its layout margins.

``` swift
public var isLayoutMarginsRelativeArrangement = false 
```

## Methods

### `replaceArrangedSubviews(with:)`

Replaces all of the current arranged subviews.

``` swift
public func replaceArrangedSubviews(with subviews: [UIView]) 
```

#### Parameters

  - subviews: The new arranged subviews.

### `addArrangedSubviews(_:)`

Adds a collection of subviews to the current arranged subviews.
If there are already arranged subviews, this will not replace the old ones.

``` swift
public func addArrangedSubviews(_ subviews: [UIView]) 
```

#### Parameters

  - subviews: The collection of subviews to be added to the arranged subviews.

### `addArrangedSubview(_:respectsLayoutMargins:)`

Adds an arranged subview to the container in the last position.

``` swift
public func addArrangedSubview(_ subview: UIView, respectsLayoutMargins: Bool? = nil) 
```

#### Parameters

  - subview: The subview to be added.
  - respectsLayoutMargins: A Boolean value that determines if the subview should preserve it's layout margins.

### `insertArrangedSubview(_:at:respectsLayoutMargins:)`

Adds an arranged subview to the container in the provided index.

``` swift
public func insertArrangedSubview(_ subview: UIView, at index: Int, respectsLayoutMargins: Bool? = nil) 
```

#### Parameters

  - subview: The subview to be added.
  - index: The position where the subview will be added in the arranged subviews.
  - respectsLayoutMargins: A Boolean value that determines if the subview should preserve it's layout margins.

### `removeAllArrangedSubviews()`

Removes all arranged subviews from the container.

``` swift
public func removeAllArrangedSubviews() 
```

### `removeArrangedSubview(_:)`

Removes an arranged subview from the container.

``` swift
public func removeArrangedSubview(_ subview: UIView) 
```

#### Parameters

  - subview: The subview to be removed.

### `updateConstraints()`

The updateConstraints is overridden so we can re-layout the constraints whenever the layout is invalidated.

``` swift
override public func updateConstraints() 
```
