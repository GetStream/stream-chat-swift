---
id: swiftuiviewcontrollerrepresentable 
title: SwiftUIViewControllerRepresentable
--- 

``` swift
@available(iOS 13.0, *)
/// A concrete type that wraps a view conforming to `SwiftUIRepresentable` and enables using it in SwiftUI via `UIViewControllerRepresentable`
public struct SwiftUIViewControllerRepresentable<
    ViewController: UIViewController &
        SwiftUIRepresentable
>: UIViewControllerRepresentable 
```

## Inheritance

`UIViewControllerRepresentable`

## Methods

### `makeUIViewController(context:)`

``` swift
public func makeUIViewController(context: Context) -> ViewController 
```

### `updateUIViewController(_:context:)`

``` swift
public func updateUIViewController(_ uiViewController: ViewController, context: Context) 
```
