---
title: InputTextViewClipboardAttachmentDelegate
---

The delegate of the `InputTextView` that notifies when an attachment is pasted in the text view.

``` swift
public protocol InputTextViewClipboardAttachmentDelegate: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### inputTextView(\_:​didPasteImage:​)

Notifies that an `UIImage` has been pasted into the text view

``` swift
func inputTextView(_ inputTextView: InputTextView, didPasteImage image: UIImage)
```

#### Parameters

  - inputTextView: The `InputTextView` in which the image was pasted
  - image: The `UIImage`
