---
title: GalleryVC
---

A viewcontroller to showcase and slide through multiple attachments
(images and videos by default).

``` swift
open class _GalleryVC<ExtraData: ExtraDataTypes>:
    _ViewController,
    UIGestureRecognizerDelegate,
    AppearanceProvider,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    ComponentsProvider 
```

## Inheritance

[`_ViewController`](../../common-views/_view-controller), [`AppearanceProvider`](../../utils/appearance-provider), [`ComponentsProvider`](../../utils/components-provider), `UICollectionViewDataSource`, `UICollectionViewDelegate`, `UICollectionViewDelegateFlowLayout`, `UIGestureRecognizerDelegate`

## Properties

### `content`

Content to display.

``` swift
open var content: Content! 
```

### `items`

Items to display.

``` swift
open var items: [AnyChatMessageAttachment] 
```

### `transitionController`

Controller for handling the transition for dismissal

``` swift
open var transitionController: ZoomTransitionController!
```

### `dateFormatter`

`DateComponentsFormatter` for showing when the message was sent.

``` swift
open private(set) lazy var dateFormatter: DateComponentsFormatter 
```

### `attachmentsFlowLayout`

`UICollectionViewFlowLayout` instance for `attachmentsCollectionView`.

``` swift
open private(set) lazy var attachmentsFlowLayout: UICollectionViewFlowLayout 
```

### `attachmentsCollectionView`

`UICollectionView` instance to display attachments.

``` swift
open private(set) lazy var attachmentsCollectionView: UICollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: attachmentsFlowLayout
    )
    .withoutAutoresizingMaskConstraints
```

### `topBarView`

Bar view displayed at the top.

``` swift
open private(set) lazy var topBarView: UIView = UIView()
        .withoutAutoresizingMaskConstraints
```

### `userLabel`

Label to show information about the user that sent the message.

``` swift
open private(set) lazy var userLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
```

### `dateLabel`

Label to show information about the date the message was sent at.

``` swift
open private(set) lazy var dateLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
```

### `bottomBarView`

Bar view displayed at the bottom.

``` swift
open private(set) lazy var bottomBarView: UIView = UIView()
        .withoutAutoresizingMaskConstraints
```

### `currentPhotoLabel`

Label to show which photo is currently being displayed.

``` swift
open private(set) lazy var currentPhotoLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
```

### `closeButton`

Button for closing this view controller.

``` swift
open private(set) lazy var closeButton: UIButton = components
        .closeButton.init()
        .withoutAutoresizingMaskConstraints
```

### `videoPlaybackBar`

View that controls the video player of currently visible cell.

``` swift
open private(set) lazy var videoPlaybackBar: _VideoPlaybackControlView<ExtraData> = components
        .videoPlaybackControlView.init()
        .withoutAutoresizingMaskConstraints
```

### `shareButton`

Button for sharing content.

``` swift
open private(set) lazy var shareButton: UIButton = components
        .shareButton.init()
        .withoutAutoresizingMaskConstraints
```

### `topBarTopConstraint`

A constaint between `topBarView.topAnchor` and `view.topAnchor`.

``` swift
open private(set) var topBarTopConstraint: NSLayoutConstraint?
```

### `bottomBarBottomConstraint`

A constaint between `bottomBarView.bottomAnchor` and `view.bottomAnchor`.

``` swift
open private(set) var bottomBarBottomConstraint: NSLayoutConstraint?
```

### `currentItemIndexPath`

An index path for the currently visible cell.

``` swift
open var currentItemIndexPath: IndexPath 
```

### `currentItem`

A currently visible gallery item.

``` swift
open var currentItem: AnyChatMessageAttachment 
```

### `imageViewToAnimateWhenDismissing`

Returns an image view to animate during interactive dismissing.

``` swift
open var imageViewToAnimateWhenDismissing: UIImageView? 
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `viewDidLoad()`

``` swift
override open func viewDidLoad() 
```

### `viewWillDisappear(_:)`

``` swift
override open func viewWillDisappear(_ animated: Bool) 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `handlePan(with:)`

Called whenever user pans with a given `gestureRecognizer`.

``` swift
@objc
    open func handlePan(with gestureRecognizer: UIPanGestureRecognizer) 
```

### `closeButtonTapped()`

Called when `closeButton` is tapped.

``` swift
@objc
    open func closeButtonTapped() 
```

### `shareButtonTapped()`

Called when `shareButton` is tapped.

``` swift
@objc
    open func shareButtonTapped() 
```

### `updateCurrentPage()`

Updates `currentPage`.

``` swift
open func updateCurrentPage() 
```

### `collectionView(_:numberOfItemsInSection:)`

``` swift
open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int 
```

### `collectionView(_:cellForItemAt:)`

``` swift
open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell 
```

### `collectionView(_:layout:sizeForItemAt:)`

``` swift
open func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize 
```

### `collectionView(_:targetContentOffsetForProposedContentOffset:)`

``` swift
open func collectionView(
        _ collectionView: UICollectionView,
        targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint
    ) -> CGPoint 
```

### `scrollViewDidEndDecelerating(_:)`

``` swift
open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) 
```

### `scrollViewDidScroll(_:)`

``` swift
open func scrollViewDidScroll(_ scrollView: UIScrollView) 
```

### `viewWillTransition(to:with:)`

``` swift
override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) 
```

### `shareItem(at:)`

Returns a share item for the gallery item at given index path.

``` swift
open func shareItem(at indexPath: IndexPath) -> Any? 
```

#### Parameters

  - indexPath: An index path.

#### Returns

An item to share.

### `cellReuseIdentifierForItem(at:)`

Returns cell reuse identifier for a gallery item at given index path.

``` swift
open func cellReuseIdentifierForItem(at indexPath: IndexPath) -> String? 
```

#### Parameters

  - indexPath: An index path.

#### Returns

A cell reuse identifier.

### `handleSingleTapOnCell(at:)`

Triggered when the current image is single tapped.

``` swift
open func handleSingleTapOnCell(at indexPath: IndexPath) 
```
