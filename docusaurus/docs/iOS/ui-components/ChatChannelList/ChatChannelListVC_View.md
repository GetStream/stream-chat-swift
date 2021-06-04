
A `UIViewControllerRepresentable` subclass which wraps `ChatChannelListVC` and shows list of channels.

``` swift
public struct View: UIViewControllerRepresentable 
```

## Inheritance

`UIViewControllerRepresentable`

## Initializers

### `init(controller:)`

``` swift
public init(controller: _ChatChannelListController<ExtraData>) 
```

## Methods

### `makeUIViewController(context:)`

``` swift
public func makeUIViewController(context: Context) -> _ChatChannelListVC<ExtraData> 
```

### `updateUIViewController(_:context:)`

``` swift
public func updateUIViewController(_ chatChannelListVC: _ChatChannelListVC<ExtraData>, context: Context) 
```
