---
title: ChatMessageListScrollOverlayDataSource
---

A protocol for `ChatMessageListScrollOverlayView` data source.

``` swift
public protocol ChatMessageListScrollOverlayDataSource: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### scrollOverlay(\_:​textForItemAt:​)

Get date for item at given index path

``` swift
func scrollOverlay(_ overlay: ChatMessageListScrollOverlayView, textForItemAt indexPath: IndexPath) -> String?
```

#### Parameters

  - overlay: A view requesting date
  - indexPath: An index path that should be used to get the date
