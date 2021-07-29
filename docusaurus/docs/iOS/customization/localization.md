---
title: Adding Localization
---

The SDK offers you in-house localization for all strings contained in UI components. For our internal localization, we provide `strings` file for each language that we translate. For advanced plural localization cases (typing indicator showing how many people are typing or how many responses are in thread), we use `stringsdict` with `NSStringPluralRuleType`. 

## Changing the device's language

Stream Chat tries to use the same language as the device it is running on. If the device is set to a language that Stream Chat does not support, then Stream Chat will default to English.
See [how to change device language](https://support.apple.com/en-us/HT204031).

## Adding new language which is not present in StreamChat

StreamChatUI uses `strings` and `stringsdict` files to handle localize the framework.
`Appearance` structure contains closure `localizationProvider`, which is responsible for deriving `localizedString` from exact bundle. 
By default, this bundle is the  `StreamChatUI` framework bundle, but you can customize it to anything you need in 3 steps:

1.If you don't have `strings` or `stringsdict` files in your project, add those new files to `Localizable.strings` and `Localizable.stringsdict`.
2. Next [add new language to the project](https://developer.apple.com/documentation/xcode/adding-support-for-languages-and-regions).
3. Copy the StreamChatUI localization keys into your `strings` and `stringsdict` files.
4. Set the `localizationProvider` to provide your `AppBundle` instead of `StreamChatUI` frameworks:
```swift
Appearance.default.localizationProvider = { key, table in
// A best practice is to use Bundle.main unless your strings are in a different bundle.
    // Note: `table` is equivalent to filename of the `Localization.strings` file without file extension. 
    // the name for `strings` and `stringsdict` should be same!
    Bundle.main.localizedString(forKey: key, value: nil, table: table)
}
```
5. Now, you're ready to implement your strings and stringsdict files for different languages.

This step is the same for overriding existing languages, because there is no user-friendly way to override just some keys from the `strings` file as the Localization is getting loaded as whole file.

:::tip
For easier implementation, it's advised to name your `strings` and `stringsdict` files as follows: `Localizable.strings`, `Localizable.stringsdict` . Also you need to name those 2 files the same. 
If you don't want to have those files named like this, be sure to set the `table` argument to your filename ( `Bundle.main.localizedString(forKey: key, value: nil, table: "MyLocalizableStrings")`)
:::

:::caution
You should assign your custom `localizationProvider`  to `Appearance.default` only. If you create your custom `Appearance`, assign the `localizationProvider` to it and assign the `appearance` to some component, expect the component to have StreamChat localization instead of your custom one.
:::

## Resources

To ease your work, you can just copy the following content of files and add it to your current Localization: 

- [`Localizable.strings`](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatUI/Resources/en.lproj/Localizable.strings)
- [`Localizable.stringsdict`](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatUI/Resources/en.lproj/Localizable.stringsdict)

For example implementation of Czech localization, you can refer to [`DemoApp`](https://github.com/GetStream/stream-chat-swift/tree/main/DemoApp) in StreamChat repository on github and take a look at `Localizable.string`, `Localizable.stringsdict` and `DemoAppCoordinator.swift` where the assignment of the localization takes place.
