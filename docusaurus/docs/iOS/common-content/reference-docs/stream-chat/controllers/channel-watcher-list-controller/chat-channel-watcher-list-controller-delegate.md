---
title: ChatChannelWatcherListControllerDelegate
---

`ChatChannelWatcherListController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatChannelWatcherListControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../../data-controller-state-delegate)

## Requirements

### channelWatcherListController(\_:​didChangeWatchers:​)

The controller observed a change in the channel watcher list.

``` swift
func channelWatcherListController(
        _ controller: ChatChannelWatcherListController,
        didChangeWatchers changes: [ListChange<ChatUser>]
    )
```
