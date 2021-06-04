
Protocol that adds delegate methods specific for `ChatMessageListCollectionView`

``` swift
public protocol ChatMessageListCollectionViewDataSource: UICollectionViewDataSource 
```

## Inheritance

`UICollectionViewDataSource`

## Requirements

### collectionView(\_:​scrollOverlayTextForItemAt:​)

Get date for item at given indexPath

``` swift
func collectionView(_ collectionView: UICollectionView, scrollOverlayTextForItemAt indexPath: IndexPath) -> String?
```

#### Parameters

  - collectionView: CollectionView requesting date
  - indexPath: IndexPath that should be used to get date
