---
id: defaultchatchannelnamer(maxmembernames_separator_) 
title: DefaultChatChannelNamer(maxMemberNames_separator_)
--- 

Generates a name for the given channel, given the current user's id.

``` swift
public func DefaultChatChannelNamer<ExtraData: ExtraDataTypes>(
    maxMemberNames: Int = 2,
    separator: String = ","
) -> _ChatChannelNamer<ExtraData> 
```

The priority order is:

  - Assigned name of the channel, if not empty

  - If the channel is direct message (implicit cid):
    
      - Name generated from cached members of the channel

  - Channel's id

Examples:

  - If channel has some name, ie. `Channel 1`, this returns `Channel 1`

  - If channel has no name and is not direct message, this returns channel ID of the channel

  - If channel is direct message, has no name and has members where there just 2,
    returns name of the members in alphabetic order: `Leia, Luke`

  - If channel is direct message, has no name and has members where there are more than 2,
    returns name of the members in alphabetic order with how many members left: `Leia, Luke and 5 others`

  - If channel is direct message, has no name and no members, this returns `nil`

  - If channel is direct message, has no name and only one member, shows the one member name

## Parameters

  - maxMemberNames: Maximum number of visible members in Channel defaults to `2`
  - separator: Separator of the members, defaults to `y`

## Returns

A closure with 2 parameters carrying `channel` used for name generation and `currentUserId` to decide which members' names are going to be displayed
