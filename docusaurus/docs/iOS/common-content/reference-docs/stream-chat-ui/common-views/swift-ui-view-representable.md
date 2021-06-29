---
title: SwiftUIViewRepresentable
---

``` swift
@available(iOS 13.0, *)
/// A concrete type that wraps a view conforming to `SwiftUIRepresentable` and enables using it in SwiftUI via `UIViewRepresentable`
public struct SwiftUIViewRepresentable<View: UIView & SwiftUIRepresentable>: UIViewRepresentable 
```

## Inheritance

`UIViewRepresentable`

## Methods

### `makeUIView(context:)`

``` swift
public func makeUIView(context: Context) -> View 
```

### `updateUIView(_:context:)`

``` swift
public func updateUIView(_ uiView: View, context: Context) 
```
