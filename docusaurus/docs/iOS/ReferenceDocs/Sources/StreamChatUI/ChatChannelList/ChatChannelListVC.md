---
id: chatchannellistvc 
title: ChatChannelListVC
slug: /ReferenceDocs/Sources/StreamChatUI/ChatChannelList/chatchannellistvc
---

A `UIViewController` subclass  that shows list of channels.

``` swift
open class _ChatChannelListVC<ExtraData: ExtraDataTypes>: _ViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    _ChatChannelListControllerDelegate,
    DataControllerStateDelegate,
    ThemeProvider,
    SwipeableViewDelegate 
```

## Inheritance

[`_ViewController`](../CommonViews/_ViewController), `DataControllerStateDelegate`, [`SwipeableViewDelegate`](SwipeableViewDelegate), [`SwiftUIRepresentable`](../CommonViews/SwiftUIRepresentable), [`ThemeProvider`](../Utils/ThemeProvider), `UICollectionViewDataSource`, `UICollectionViewDelegate`, `_ChatChannelListControllerDelegate`

## Properties

### `content`

``` swift
public var content: _ChatChannelListController<ExtraData> 
```

### `controller`

The `ChatChannelListController` instance that provides channels data.

``` swift
public var controller: _ChatChannelListController<ExtraData>!
```

### `loadingIndicator`

``` swift
open private(set) lazy var loadingIndicator: UIActivityIndicatorView 
```

### `router`

A router object responsible for handling navigation actions of this view controller.

``` swift
open lazy var router: _ChatChannelListRouter<ExtraData> 
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

### `createChannelButton`

The `UIButton` instance used for navigating to new channel screen creation,

``` swift
open private(set) lazy var createChannelButton: UIButton = components
        .createChannelButton.init()
        .withoutAutoresizingMaskConstraints
```

### `userAvatarView`

The `CurrentChatUserAvatarView` instance used for displaying avatar of the current user.

``` swift
open private(set) lazy var userAvatarView: _CurrentChatUserAvatarView<ExtraData> = components
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

### `scrollViewDidEndDecelerating(_:)`

``` swift
open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) 
```

### `didTapOnCurrentUserAvatar(_:)`

``` swift
@objc open func didTapOnCurrentUserAvatar(_ sender: Any) 
```

### `didTapCreateNewChannel(_:)`

``` swift
@objc open func didTapCreateNewChannel(_ sender: Any) 
```

### `traitCollectionDidChange(_:)`

``` swift
override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) 
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
open func controllerWillChangeChannels(_ controller: _ChatChannelListController<ExtraData>) 
```

### `controller(_:didChangeChannels:)`

``` swift
open func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
open func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
