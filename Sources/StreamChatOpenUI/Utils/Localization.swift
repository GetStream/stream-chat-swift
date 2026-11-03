//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import os

@available(iOS 17.0, macOS 14.0, *)
enum L10n {
    enum Action {
        static var untitled: String {
            localized("action.untitled", comment: "The person's message when they tap a control that has no label.")
        }
    }

    enum Select {
        static var placeholder: String {
            localized("select.placeholder", comment: "Shown in a select field until an option is picked.")
        }
    }

    enum DatePicker {
        static var from: String {
            localized("date_picker.from", comment: "The start of a date range.")
        }

        static var to: String {
            localized("date_picker.to", comment: "The end of a date range.")
        }

        static var date: String {
            localized("date_picker.date", comment: "The label of a single date field.")
        }

        static var choose: String {
            localized("date_picker.choose", comment: "Picks a date for a field that has none yet.")
        }
    }

    enum Slider {
        static func lower(_ label: String) -> String {
            String(format: localized("slider.lower", comment: "The lower end of a range slider. The argument is the slider's label."), label)
        }

        static func upper(_ label: String) -> String {
            String(format: localized("slider.upper", comment: "The upper end of a range slider. The argument is the slider's label."), label)
        }
    }

    enum Toggle {
        static var checked: String {
            localized("toggle.checked", comment: "The value of a checked checkbox.")
        }

        static var unchecked: String {
            localized("toggle.unchecked", comment: "The value of an unchecked checkbox.")
        }
    }

    enum Disclosure {
        static var expanded: String {
            localized("disclosure.expanded", comment: "The value of an open accordion or section.")
        }

        static var collapsed: String {
            localized("disclosure.collapsed", comment: "The value of a closed accordion or section.")
        }
    }

    enum Modal {
        static var close: String {
            localized("modal.close", comment: "Closes a dialog.")
        }
    }

    enum Pagination {
        static var previousPage: String {
            localized("pagination.previous_page", comment: "Shows the previous page of a table.")
        }

        static var nextPage: String {
            localized("pagination.next_page", comment: "Shows the next page of a table.")
        }

        static func position(_ page: Int, of pages: Int) -> String {
            String(
                format: localized("pagination.position", comment: "The page a table shows, such as 1 / 3. The arguments are the page and the number of pages."),
                NumberFormatting.integer(page),
                NumberFormatting.integer(pages)
            )
        }

        static func positionAccessibility(_ page: Int, of pages: Int) -> String {
            String(
                format: localized("pagination.position_accessibility", comment: "The page a table shows, read by VoiceOver. The arguments are the page and the number of pages."),
                NumberFormatting.integer(page),
                NumberFormatting.integer(pages)
            )
        }
    }

    enum Carousel {
        static var previous: String {
            localized("carousel.previous", comment: "Scrolls a carousel to its previous slide.")
        }

        static var next: String {
            localized("carousel.next", comment: "Scrolls a carousel to its next slide.")
        }

        static func position(_ slide: Int, of slides: Int) -> String {
            String(
                format: localized("carousel.position", comment: "The slide a carousel shows, read by VoiceOver. The arguments are the slide and the number of slides."),
                NumberFormatting.integer(slide),
                NumberFormatting.integer(slides)
            )
        }
    }

    enum Table {
        static var loading: String {
            localized("table.loading", comment: "Read by VoiceOver while a table's data loads.")
        }
    }

    enum EditableTable {
        static func changes(_ count: Int) -> String {
            String.localizedStringWithFormat(
                localized("editable_table.changes", comment: "How many cells of a table were edited."),
                count
            )
        }

        static var reset: String {
            localized("editable_table.reset", comment: "Discards a table's edits.")
        }

        static var save: String {
            localized("editable_table.save", comment: "Saves a table's edits.")
        }
    }

    enum Sources {
        static var title: String {
            localized("sources.title", comment: "The title above a response's sources.")
        }

        static var untitled: String {
            localized("sources.untitled", comment: "The name of a source without a title.")
        }
    }

    enum Gallery {
        static var done: String {
            localized("gallery.done", comment: "Closes the full-screen image preview.")
        }
    }

    enum Chart {
        static var total: String {
            localized("chart.total", comment: "The label under the sum in a donut chart.")
        }

        static var category: String {
            localized("chart.axis.category", comment: "The name of a chart's category axis, read by VoiceOver.")
        }

        static var value: String {
            localized("chart.axis.value", comment: "The name of a chart's value axis, read by VoiceOver.")
        }

        static var series: String {
            localized("chart.axis.series", comment: "The name of a chart's series, read by VoiceOver.")
        }
    }

    enum CodeBlock {
        static var languageFallback: String {
            localized("code_block.language_fallback", comment: "The title of a code block without a language.")
        }

        static var copy: String {
            localized("code_block.copy", comment: "Copies a code block.")
        }

        static var copied: String {
            localized("code_block.copied", comment: "Said for a moment once a code block is copied.")
        }
    }

    enum Trend {
        static func up(_ percent: String) -> String {
            String(format: localized("trend.up", comment: "A metric that went up, read by VoiceOver. The argument is the change in percent."), percent)
        }

        static func down(_ percent: String) -> String {
            String(format: localized("trend.down", comment: "A metric that went down, read by VoiceOver. The argument is the change in percent."), percent)
        }
    }

    enum CardBlock {
        static func snippet(_ index: Int) -> String {
            String(format: localized("card_block.snippet", comment: "The message sent for a tapped card without a title. The argument is its number."), String(index))
        }

        static func overview(_ index: Int) -> String {
            String(format: localized("card_block.overview", comment: "The message sent for a tapped card without a title. The argument is its number."), String(index))
        }

        static func context(_ index: Int) -> String {
            String(format: localized("card_block.context", comment: "The message sent for a tapped card without a title. The argument is its number."), String(index))
        }

        static func composite(_ index: Int) -> String {
            String(format: localized("card_block.composite", comment: "The message sent for a tapped card without a title. The argument is its number."), String(index))
        }

        static func visual(_ index: Int) -> String {
            String(format: localized("card_block.visual", comment: "The message sent for a tapped card without a title. The argument is its number."), String(index))
        }
    }

    enum Validation {
        static var required: String {
            localized("validation.required", comment: "A required form field that is empty.")
        }

        static var requiredOption: String {
            localized("validation.required_option", comment: "A required group of checkboxes with none checked.")
        }

        static var email: String {
            localized("validation.email", comment: "A form field whose text isn't an email address.")
        }

        static var url: String {
            localized("validation.url", comment: "A form field whose text isn't a URL.")
        }

        static var numeric: String {
            localized("validation.numeric", comment: "A form field whose text isn't a number.")
        }

        static func min(_ minimum: String) -> String {
            String(format: localized("validation.min", comment: "A number below the field's minimum. The argument is the minimum."), minimum)
        }

        static func max(_ maximum: String) -> String {
            String(format: localized("validation.max", comment: "A number above the field's maximum. The argument is the maximum."), maximum)
        }

        static func minLength(_ minimum: String) -> String {
            String(format: localized("validation.min_length", comment: "A text shorter than the field allows. The argument is the minimum length."), minimum)
        }

        static func maxLength(_ maximum: String) -> String {
            String(format: localized("validation.max_length", comment: "A text longer than the field allows. The argument is the maximum length."), maximum)
        }

        static var pattern: String {
            localized("validation.pattern", comment: "A form field whose text doesn't match the expected format.")
        }
    }

    private static func localized(_ key: String, comment: StaticString) -> String {
        OpenUITheme.localizationProvider(key, "Localizable")
    }
}

@available(iOS 17.0, macOS 14.0, *)
enum LocalizationProviderStorage {
    typealias Provider = @Sendable (_ key: String, _ table: String) -> String

    // Boxed, so storing a provider that wraps the previous one doesn't wrap it in conversion
    // thunks each time it is read and written back.
    private final class Box: Sendable {
        let provider: Provider

        init(_ provider: @escaping Provider) {
            self.provider = provider
        }
    }

    static let defaultProvider: Provider = { key, table in
        Bundle.streamChatOpenUI.localizedString(forKey: key, value: nil, table: table)
    }

    private static let box = OSAllocatedUnfairLock(initialState: Box(defaultProvider))

    static var current: Provider {
        get { box.withLock { $0 }.provider }
        set {
            let replacement = Box(newValue)
            box.withLock { $0 = replacement }
        }
    }
}
