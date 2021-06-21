---
id: randomaccesscollection 
title: RandomAccessCollection
slug: referencedocs/sources/streamchat/utils/randomaccesscollection
---

## Methods

### `lazyCachedMap(_:)`

Lazily apply transformation to sequence

``` swift
public func lazyCachedMap<T>(_ transformation: @escaping (Element) -> T) -> LazyCachedMapCollection<T> 
```
