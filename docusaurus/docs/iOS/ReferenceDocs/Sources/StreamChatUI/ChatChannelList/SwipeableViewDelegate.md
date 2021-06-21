---
id: swipeableviewdelegate 
title: SwipeableViewDelegate
--- 

Delegate responsible for easily assigning swipe action buttons to collectionView cells.

``` swift
public protocol SwipeableViewDelegate: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### swipeableViewWillShowActionViews(for:​)

Prepares the receiver that showing of actionViews will ocur.
use this method to for example close other actionViews in your collectionView/tableView.

``` swift
func swipeableViewWillShowActionViews(for indexPath: IndexPath)
```

#### Parameters

  - indexPath: IndexPath of `collectionViewCell` which asks for action buttons.

### swipeableViewActionViews(for:​)

`ChatChannelListCollectionViewCell` can have swipe to delete / reveal action buttons on the cell.

``` swift
func swipeableViewActionViews(for indexPath: IndexPath) -> [UIView]
```

implementation of method should create those buttons and actions and be assigned easily to the cell
in `UICollectionViewDataSource.cellForItemAtIndexPath` function.

  - Returns array of buttons revealed by swipe deletion.

#### Parameters

  - indexPath: IndexPath of `collectionViewCell` which asks for action buttons.
