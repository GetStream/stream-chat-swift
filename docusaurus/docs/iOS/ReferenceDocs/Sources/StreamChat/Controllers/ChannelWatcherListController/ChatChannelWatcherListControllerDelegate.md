---
id: chatchannelwatcherlistcontrollerdelegate 
title: ChatChannelWatcherListControllerDelegate
slug: referencedocs/sources/streamchat/controllers/channelwatcherlistcontroller/chatchannelwatcherlistcontrollerdelegate
---

``` swift
public protocol _ChatChannelWatcherListControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../DataControllerStateDelegate)

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### channelWatcherListController(\_:​didChangeWatchers:​)

The controller observed a change in the channel watcher list.

``` swift
func channelWatcherListController(
        _ controller: _ChatChannelWatcherListController<ExtraData>,
        didChangeWatchers changes: [ListChange<_ChatUser<ExtraData.User>>]
    )
```
