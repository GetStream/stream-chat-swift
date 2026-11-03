//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import SwiftUI
import Testing

@MainActor
@Suite("Form components")
struct FormComponentTests {
    static let selectionForm = """
    root = Card([form])
    form = Form("trip", Buttons([Button("Go")]), [pace, stops])
    pace = FormControl("Pace", Chips("pace", "single", [ChipItem("slow", "Slow"), ChipItem("fast", "Fast")], null, "fast"))
    stops = FormControl("Stops", OptionCards("stops", "multiple", [OptionCard("lake", "Lake"), OptionCard("town", "Town")], null, ["lake", "town"]))
    """

    @Test func selectionDefaultsAreSavedOnceStreamingEnds() async {
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: Self.selectionForm, isStreaming: true)
        let host = HostedView(OpenUIView(runtime: runtime))
        defer { host.close() }
        await host.settle()

        #expect(runtime.fieldValue(formName: "trip", name: "pace") == nil)
        #expect(runtime.fieldValue(formName: "trip", name: "stops") == nil)

        runtime.update(response: Self.selectionForm, isStreaming: false)
        await host.settle()

        #expect(runtime.fieldValue(formName: "trip", name: "pace") == "fast")
        #expect(runtime.fieldValue(formName: "trip", name: "stops") == ["lake", "town"])
    }

    @Test func selectionDefaultsDontReplaceAChoice() async {
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: Self.selectionForm, isStreaming: true)
        runtime.setFieldValue(formName: "trip", componentType: "Chips", name: "pace", value: "slow")
        let host = HostedView(OpenUIView(runtime: runtime))
        defer { host.close() }
        await host.settle()

        runtime.update(response: Self.selectionForm, isStreaming: false)
        await host.settle()

        #expect(runtime.fieldValue(formName: "trip", name: "pace") == "slow")
    }

    @Test func selectionDefaultIsSavedWhenTheFieldAppearsAfterStreaming() {
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: Self.selectionForm, isStreaming: false)

        SelectionField.hydrateDefault(runtime: runtime, formName: "trip", componentType: "Chips", name: "pace", single: true, defaultValue: ["fast", "slow"])

        #expect(runtime.fieldValue(formName: "trip", name: "pace") == "fast")
    }

    @Test func sliderReadsOneValueOrARange() {
        let bounds = SliderValues.bounds(minimum: 0, maximum: 1000)

        #expect(SliderValues.values([200, 800], in: bounds) == [200, 800])
        #expect(SliderValues.values([800, 200], in: bounds) == [200, 800])
        #expect(SliderValues.values([300], in: bounds) == [300])
        #expect(SliderValues.values(450, in: bounds) == [450])
        #expect(SliderValues.values("75", in: bounds) == [75])
        #expect(SliderValues.values([-5, 5000], in: bounds) == [0, 1000])
        #expect(SliderValues.values(nil, in: bounds) == [0])
        #expect(SliderValues.values(["x"], in: bounds) == [0])
    }

    @Test func sliderBoundsStayUsable() {
        #expect(SliderValues.bounds(minimum: nil, maximum: nil) == 0...100)
        #expect(SliderValues.bounds(minimum: 10, maximum: 10) == 10...11)
        #expect(SliderValues.bounds(minimum: .nan, maximum: .infinity) == 0...100)
    }

    @Test func rangeThumbsDontCross() {
        #expect(SliderValues.setting([200, 800], index: 0, to: 300) == [300, 800])
        #expect(SliderValues.setting([200, 800], index: 0, to: 900) == [800, 800])
        #expect(SliderValues.setting([200, 800], index: 1, to: 100) == [200, 200])
        #expect(SliderValues.setting([200], index: 0, to: 900) == [900])
        #expect(SliderValues.setting([200], index: 1, to: 900) == [200])
    }

    @Test func slidersWithTooManyStepsShowInAWindow() async {
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: """
        root = Card([form])
        form = Form("filters", Buttons([Button("Apply")]), [wide, fine])
        wide = FormControl("Wide", Slider("wide", "discrete", 0, 1e15))
        fine = FormControl("Fine", Slider("fine", "continuous", 0, 100, 1e-8))
        """, isStreaming: false)
        let host = HostedView(OpenUIView(runtime: runtime))
        defer { host.close() }

        await host.settle()

        #expect(runtime.root != nil)
    }

    @Test func sliderStoresRoundedNumbers() {
        #expect(SliderValues.stored([200.12345, 799.9999]) == [200.123, 800])
        #expect(SliderValues.stored([5]) == [5])
    }

    @Test func rangeThumbsHaveTheirOwnLabels() {
        #expect(SliderValues.accessibilityLabel("Price", index: 0, count: 1) == "Price")
        #expect(SliderValues.accessibilityLabel("Price", index: 0, count: 2) == "Price, minimum")
        #expect(SliderValues.accessibilityLabel("Price", index: 1, count: 2) == "Price, maximum")
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func rangeSliderRenders(_ colorScheme: ColorScheme) {
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: """
        root = Card([form])
        form = Form("filters", Buttons([Button("Apply")]), [price])
        price = FormControl("Price", Slider("price", "continuous", 0, 1000, 50, [200, 800], "Price"))
        """, isStreaming: false)

        #expect(RenderingTests.render(runtime, colorScheme: colorScheme) != nil)
        #expect(runtime.fieldValue(formName: "filters", name: "price") == nil)
    }
}
