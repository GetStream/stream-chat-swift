---
title: ChatMessageListVCDataSource
---

The object that acts as the data source of the message list.

``` swift
public protocol ChatMessageListVCDataSource: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### channel(for:​)

Asks the data source to return the channel for the given message list.

``` swift
func channel(for vc: ChatMessageListVC) -> ChatChannel?
```

#### Parameters

  - vc: The message list requesting the channel.

### numberOfMessages(in:​)

Asks the data source to return the number of messages in the message list.

``` swift
func numberOfMessages(in vc: ChatMessageListVC) -> Int
```

#### Parameters

  - vc: The message list requesting the number of messages.

### chatMessageListVC(\_:​messageAt:​)

Asks the data source for the message in a particular location of the message list.

``` swift
func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageAt indexPath: IndexPath
    ) -> ChatMessage?
```

#### Parameters

  - vc: The message list requesting the message.
  - indexPath: An index path locating the row in the message list.

### chatMessageListVC(\_:​messageLayoutOptionsAt:​)

Asks the data source for the message layout options in a particular location of the message list.

``` swift
func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions
```

#### Parameters

  - vc: The message list requesting the layout options.
  - indexPath: An index path locating the row in the message list.
