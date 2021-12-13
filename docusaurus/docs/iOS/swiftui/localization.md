---
title: Localization
---

## Introduction

If your app supports multiple languages, the chat SDK has support for localizations. For example, you can add more languages, or you can change translations for the existing texts used throughout the SDK.

## Adding a New Language

1. If you don't have `strings` or `stringsdict` files in your project, add those new files to `Localizable.strings` and `Localizable.stringsdict`.
2. Next [add new language to the project](https://developer.apple.com/documentation/xcode/adding-support-for-languages-and-regions).
3. Copy the StreamChatUI localization keys into your `strings` and `stringsdict` files. You can find the latest version [here](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatSwiftUI/Resources/en.lproj/).
4. Set the `localizationProvider` to provide your `Bundle` instead of the one provided by `StreamChatSwiftUI` SDK (as early as possible in the App lifecylce, e.g. in the `AppDelegate`):
```swift
Appearance.localizationProvider = { key, table in
    Bundle.main.localizedString(forKey: key, value: nil, table: table)
}
```
5. Now, you're ready to implement your `strings` and `stringsdict` files for different languages.

:::tip
We recommend naming your `strings` and `stringsdict` files: `Localizable.strings` and `Localizable.stringsdict`.
:::

## Override Existing Languages

Overriding the existing language works in the same as adding a new language.

## Resources

Every string included in StreamChat can be changed and translated to a different language. All strings used by UI components are in these two files:

- [`Localizable.strings`](https://github.com/GetStream/stream-chat-swiftui/blob/main/Sources/StreamChatSwiftUI/Resources/en.lproj/Localizable.strings) 
- [`Localizable.stringsdict`](https://github.com/GetStream/stream-chat-swiftui/blob/main/Sources/StreamChatSwiftUI/Resources/en.lproj/Localizable.stringsdict)
