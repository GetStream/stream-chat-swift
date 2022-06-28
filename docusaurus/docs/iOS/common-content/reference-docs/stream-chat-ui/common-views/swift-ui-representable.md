---
title: SwiftUIRepresentable [Deprecated]
---

This has been deprecated, please refer to the SwiftUI dedicated SDK at https://github.com/GetStream/stream-chat-swiftui.

Protocol with necessary properties to make `SwiftUIRepresentable` instance

``` swift
public protocol SwiftUIRepresentable: AnyObject 
```

## Inheritance

`AnyObject`

## Default Implementations

### `asView(_:)`

Creates `SwiftUIViewRepresentable` instance wrapping the current type that can be used in your SwiftUI view

``` swift
static func asView(_ content: ViewContent) -> SwiftUIViewRepresentable<Self> 
```

#### Parameters

  - content: Content of the view. Its value is automatically updated when it's changed

### `asView(_:)`

Creates `SwiftUIViewControllerRepresentable` instance wrapping the current type that can be used in your SwiftUI view

``` swift
static func asView(_ content: ViewContent) -> SwiftUIViewControllerRepresentable<Self> 
```

#### Parameters

  - content: Content of the view controller. Its value is automatically updated when it's changed

## Requirements

### ViewContent

Type used for `content` property

``` swift
associatedtype ViewContent
```

### content

Content of a given view

``` swift
var content: ViewContent 
```
