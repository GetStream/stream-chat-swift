//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

// Two tests set the shared provider, so they must not overlap.
@Suite("Localization", .serialized)
struct LocalizationTests {
    @Test func textsComeFromTheModuleStrings() {
        #expect(L10n.Select.placeholder == "Select...")
        #expect(L10n.DatePicker.choose == "Choose")
        #expect(L10n.Modal.close == "Close")
        #expect(L10n.EditableTable.save == "Save Changes")
        #expect(L10n.CodeBlock.languageFallback == "code")
        #expect(L10n.Validation.minLength("5") == "Must be at least 5 characters")
        #expect(L10n.Slider.lower("Price") == "Price, minimum")
        #expect(L10n.CardBlock.snippet(2) == "Snippet card 2")
    }

    @Test func changeCountUsesPluralRules() {
        #expect(L10n.EditableTable.changes(1) == "1 change")
        #expect(L10n.EditableTable.changes(3) == "3 changes")
    }

    @Test func pagePositionsAreFormatted() {
        #expect(L10n.Pagination.position(1, of: 3) == "1 / 3")
        #expect(L10n.Pagination.positionAccessibility(2, of: 3) == "Page 2 of 3")
        #expect(L10n.Carousel.position(1, of: 4) == "Slide 1 of 4")
    }

    @Test func everyKeyHasAnEnglishText() throws {
        let url = try #require(Bundle.streamChatOpenUI.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: "en"))
        let strings = try #require(NSDictionary(contentsOf: url) as? [String: String])

        #expect(strings.count > 40)
        for (key, value) in strings {
            #expect(!value.isEmpty, "\(key)")
            #expect(LocalizationProviderStorage.defaultProvider(key, "Localizable") == value, "\(key)")
        }
    }

    @Test func appsCanReplaceTheTexts() {
        let original = OpenUITheme.localizationProvider
        defer { OpenUITheme.localizationProvider = original }
        OpenUITheme.localizationProvider = { key, table in
            key == "editable_table.reset" ? "Zurücksetzen" : original(key, table)
        }

        #expect(L10n.EditableTable.reset == "Zurücksetzen")
        #expect(L10n.Modal.close == "Close")
    }

    @Test func providersCanBeReadAndWrittenBackRepeatedly() {
        for _ in 0..<20000 {
            OpenUITheme.localizationProvider = OpenUITheme.localizationProvider
        }

        #expect(L10n.Modal.close == "Close")
    }

    @Test func displayedNumbersFollowTheLocale() {
        #expect(NumberFormatting.integer(3) == 3.formatted(.number))
        #expect(NumberFormatting.decimal(1234.5) == 1234.5.formatted(.number.precision(.fractionLength(0...6))))
        #expect(NumberFormatting.decimal(0.1 + 0.2) == 0.3.formatted(.number))
        #expect(NumberFormatting.decimal(.infinity) == "Infinity")
        #expect(NumberFormatting.percent(25) == 0.25.formatted(.percent))
        #expect(NumberFormatting.percent(12.5) == 0.125.formatted(.percent.precision(.fractionLength(0...2))))
    }
}
