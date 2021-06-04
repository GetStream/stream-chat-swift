
SwiftUI wrapper of `_ChatChannelAvatarView`.

``` swift
public class SwiftUIWrapper<Content: SwiftUIView>: _ChatChannelAvatarView<ExtraData>, ObservableObject
        where Content.ExtraData == ExtraData
```

## Inheritance

`ObservableObject`, `_ChatChannelAvatarView<ExtraData>`

## Properties

### `intrinsicContentSize`

``` swift
override public var intrinsicContentSize: CGSize 
```

## Methods

### `setUp()`

``` swift
override public func setUp() 
```

### `setUpLayout()`

``` swift
override public func setUpLayout() 
```

### `updateContent()`

``` swift
override public func updateContent() 
```
