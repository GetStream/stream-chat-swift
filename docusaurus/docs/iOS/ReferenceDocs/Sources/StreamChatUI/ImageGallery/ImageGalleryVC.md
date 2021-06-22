---
id: imagegalleryvc 
title: ImageGalleryVC
slug: /ReferenceDocs/Sources/StreamChatUI/ImageGallery/imagegalleryvc
---

View controller to showcase and slide through multiple images.

``` swift
open class _ImageGalleryVC<ExtraData: ExtraDataTypes>:
    _ViewController,
    UIGestureRecognizerDelegate,
    AppearanceProvider,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout 
```

## Inheritance

[`_ViewController`](../CommonViews/_ViewController), [`AppearanceProvider`](../Utils/AppearanceProvider), `UICollectionViewDataSource`, `UICollectionViewDelegate`, `UICollectionViewDelegateFlowLayout`, `UIGestureRecognizerDelegate`

## Properties

### `content`

Content to display.

``` swift
open var content: _ChatMessage<ExtraData>! 
```

### `images`

Images to display (`content.imageAttachments`).

``` swift
open var images: [ChatMessageImageAttachment] = []
```

### `currentPage`

Currently displayed image (indexed from 0).

``` swift
open var currentPage: Int = 0 
```

### `initialAttachment`

Attachment to be displayed initially.

``` swift
open var initialAttachment: ChatMessageImageAttachment!
```

### `transitionController`

Controller for handling the transition for dismissal

``` swift
open var transitionController: ZoomTransitionController!
```

### `dateFormatter`

`DateComponentsFormatter` for showing when the message was sent.

``` swift
public private(set) lazy var dateFormatter: DateComponentsFormatter 
```

### `attachmentsFlowLayout`

`UICollectionViewFlowLayout` instance for `attachmentsCollectionView`.

``` swift
public private(set) lazy var attachmentsFlowLayout 
```

### `attachmentsCollectionView`

`UICollectionView` instance to display attachments.

``` swift
public private(set) lazy var attachmentsCollectionView: UICollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: attachmentsFlowLayout
    )
    .withoutAutoresizingMaskConstraints
```

### `topBarView`

Bar view displayed at the top.

``` swift
public private(set) lazy var topBarView = UIView()
        .withoutAutoresizingMaskConstraints
```

### `userLabel`

Label to show information about the user that sent the message.

``` swift
public private(set) lazy var userLabel = UILabel()
        .withoutAutoresizingMaskConstraints
```

### `dateLabel`

Label to show information about the date the message was sent at.

``` swift
public private(set) lazy var dateLabel = UILabel()
        .withoutAutoresizingMaskConstraints
```

### `bottomBarView`

Bar view displayed at the bottom.

``` swift
public private(set) lazy var bottomBarView = UIView()
        .withoutAutoresizingMaskConstraints
```

### `currentPhotoLabel`

Label to show which photo is currently being displayed.

``` swift
public private(set) lazy var currentPhotoLabel = UILabel()
        .withoutAutoresizingMaskConstraints
```

### `closeButton`

Button for closing this view controller.

``` swift
public private(set) lazy var closeButton 
```

### `shareButton`

Button for sharing content.

``` swift
public private(set) lazy var shareButton 
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

### `imageSingleTapped()`

Triggered when the current image is single tapped.

``` swift
open func imageSingleTapped() 
```

### `viewWillTransition(to:with:)`

``` swift
override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) 
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
public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) 
```
