---
id: userextradata 
title: UserExtraData
slug: referencedocs/sources/streamchat/models/userextradata
---

You need to make your custom type conforming to this protocol if you want to use it for extending `ChatUser` entity with your
custom additional data.

``` swift
public protocol UserExtraData: ExtraData 
```

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

[`ExtraData`](ExtraData)
