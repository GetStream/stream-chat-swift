---
title: ChatChannelListController
---

`ChatChannelListController` allows you to observe a list of chat channels based on the provided query and to paginate channels.

## ChatChannelListControllerDelegate

Classes that conform to this protocol will receive changes to the queried list of channels.

```swift
func controller(
    _ controller: ChatChannelListController,
    didChangeChannels changes: [ListChange<ChatChannel>]
)
```
