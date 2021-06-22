---
id: randomaccesscollection 
title: RandomAccessCollection
slug: /ReferenceDocs/Sources/StreamChat/Utils/randomaccesscollection
---

## Methods

### `lazyCachedMap(_:)`

Lazily apply transformation to sequence

``` swift
public func lazyCachedMap<T>(_ transformation: @escaping (Element) -> T) -> LazyCachedMapCollection<T> 
```
