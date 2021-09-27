---
title: ChatChannelListVC
---

A `UIViewController` subclass  that shows list of channels.

``` swift
@available(iOSApplicationExtension, unavailable)
open class ChatChannelListVC: _ViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    ChatChannelListControllerDelegate,
    DataControllerStateDelegate,
    ThemeProvider,
    SwipeableViewDelegate 
```

## Inheritance

[`_ViewController`](../../common-views/_view-controller), `ChatChannelListControllerDelegate`, `DataControllerStateDelegate`, [`SwipeableViewDelegate`](../swipeable-view-delegate), [`SwiftUIRepresentable`](../../common-views/swift-ui-representable), [`ThemeProvider`](../../utils/theme-provider), `UICollectionViewDataSource`, `UICollectionViewDelegate`

## Properties

### `content`

``` swift
public var content: ChatChannelListController 
```

### `controller`

The `ChatChannelListController` instance that provides channels data.

``` swift
public var controller: ChatChannelListController!
```

### `loadingIndicator`

``` swift
open private(set) lazy var loadingIndicator: UIActivityIndicatorView 
```

### `router`

A router object responsible for handling navigation actions of this view controller.

``` swift
open lazy var router: ChatChannelListRouter 
```

### `collectionViewLayout`

The `UICollectionViewLayout` that used by `ChatChannelListCollectionView`.

``` swift
open private(set) lazy var collectionViewLayout: UICollectionViewLayout 
```

### `collectionView`

The `UICollectionView` instance that displays channel list.

``` swift
open private(set) lazy var collectionView: UICollectionView =
        UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
            .withoutAutoresizingMaskConstraints
```

### `userAvatarView`

The `CurrentChatUserAvatarView` instance used for displaying avatar of the current user.

``` swift
open private(set) lazy var userAvatarView: CurrentChatUserAvatarView = components
        .currentUserAvatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `separatorReuseIdentifier`

Reuse identifier of separator

``` swift
open var separatorReuseIdentifier: String 
```

### `collectionViewCellReuseIdentifier`

Reuse identifier of `collectionViewCell`

``` swift
open var collectionViewCellReuseIdentifier: String 
```

## Methods

### `setUp()`

``` swift
override open func setUp() 
```

### `collectionView(_:willDisplay:forItemAt:)`

``` swift
open func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `collectionView(_:numberOfItemsInSection:)`

``` swift
open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int 
```

### `collectionView(_:cellForItemAt:)`

``` swift
open func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell 
```

### `collectionView(_:viewForSupplementaryElementOfKind:at:)`

``` swift
open func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView 
```

### `collectionView(_:didSelectItemAt:)`

``` swift
open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) 
```

### `didTapOnCurrentUserAvatar(_:)`

``` swift
@objc open func didTapOnCurrentUserAvatar(_ sender: Any) 
```

### `traitCollectionDidChange(_:)`

``` swift
override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) 
```

### `loadMoreChannels()`

``` swift
open func loadMoreChannels() 
```

### `swipeableViewWillShowActionViews(for:)`

``` swift
open func swipeableViewWillShowActionViews(for indexPath: IndexPath) 
```

### `swipeableViewActionViews(for:)`

``` swift
open func swipeableViewActionViews(for indexPath: IndexPath) -> [UIView] 
```

### `deleteButtonPressedForCell(at:)`

This function is called when delete button is pressed from action items of a cell.

``` swift
open func deleteButtonPressedForCell(at indexPath: IndexPath) 
```

#### Parameters

  - indexPath: IndexPath of given cell to fetch the content of it.

### `moreButtonPressedForCell(at:)`

This function is called when more button is pressed from action items of a cell.

``` swift
open func moreButtonPressedForCell(at indexPath: IndexPath) 
```

#### Parameters

  - indexPath: IndexPath of given cell to fetch the content of it.

### `controllerWillChangeChannels(_:)`

``` swift
open func controllerWillChangeChannels(_ controller: ChatChannelListController) 
```

### `controller(_:didChangeChannels:)`

``` swift
open func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
open func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
