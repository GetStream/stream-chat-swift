---
title: ChatMessageListViewDataSource
---

A protocol for `ChatMessageListView` delegate.

``` swift
public protocol ChatMessageListViewDataSource: UITableViewDataSource 
```

## Inheritance

`UITableViewDataSource`

## Requirements

### messageListView(\_:​scrollOverlayTextForItemAt:​)

Get date for item at given index path

``` swift
func messageListView(_ listView: UITableView, scrollOverlayTextForItemAt indexPath: IndexPath) -> String?
```

#### Parameters

  - listView: A view requesting date
  - indexPath: An index path that should be used to get the date
