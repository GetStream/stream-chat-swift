---
title: ListCollectionViewLayoutDelegate
---

The `ListCollectionViewLayout` delegate to control how to display the list.

``` swift
public protocol ListCollectionViewLayoutDelegate: UICollectionViewDelegate 
```

## Inheritance

`UICollectionViewDelegate`

## Requirements

### collectionView(\_:​layout:​shouldShowSeparatorForCellAtIndexPath:​)

Implement this method to have detailed control over the visibility of the cell separators.

``` swift
func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: ListCollectionViewLayout,
        shouldShowSeparatorForCellAtIndexPath indexPath: IndexPath
    ) -> Bool
```
