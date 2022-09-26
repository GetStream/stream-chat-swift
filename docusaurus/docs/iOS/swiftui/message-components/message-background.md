---
title: Message Background Color
---

If you want to change the background of the message bubbles, you can update the `messageCurrentUserBackground` and `messageOtherUserBackground` in the `ColorPalette` on `StreamChat` setup. These values are arrays of `UIColor` - if you want to have a gradient background just provide all the colors that the gradient should be consisted of.

```swift
var colors = ColorPalette()
colors.messageCurrentUserBackground = [UIColor.red, UIColor.white]
colors.messageOtherUserBackground = [UIColor.white, UIColor.red]

let appearance = Appearance(colors: colors)

streamChat = StreamChat(chatClient: chatClient, appearance: appearance)
```
