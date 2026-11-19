//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

@Suite("Editable table")
struct EditableTableTests {
    let keys = ["name", "qty"]
    let complete: OpenUIValue = [
        ["id": "1", "values": ["Apples", 3]],
        ["id": "2", "values": ["Pears", 5]]
    ]

    @Test func partialRowsWhileStreamingDontCountAsChanges() {
        var table = EditableTableRows()
        table.load([["id": "1", "values": ["App"]]], keys: keys, isStreaming: true)
        table.load([["id": "1", "values": ["Apples", 3]], ["id": "2"]], keys: keys, isStreaming: true)
        table.load(complete, keys: keys, isStreaming: true)

        #expect(table.baseline == nil)
        #expect(table.changedCellCount(keys: keys) == 0)

        table.load(complete, keys: keys, isStreaming: false)

        #expect(table.rows.count == 2)
        #expect(table.changedCellCount(keys: keys) == 0)
    }

    @Test func editsAreCountedResetAndSaved() {
        var table = EditableTableRows()
        table.load(complete, keys: keys, isStreaming: false)

        table.rows[0]["qty"] = 4
        table.rows[1]["name"] = "Plums"
        #expect(table.changedCellCount(keys: keys) == 2)

        table.reset()
        #expect(table.changedCellCount(keys: keys) == 0)
        #expect(table.rows[0]["qty"] == 3)

        table.rows[0]["qty"] = 7
        #expect(table.data(keys: keys) == [
            ["id": "1", "values": ["Apples", 7]],
            ["id": "2", "values": ["Pears", 5]]
        ])
        table.markSaved()
        #expect(table.changedCellCount(keys: keys) == 0)
    }

    @Test func rowsALaterStreamWritesAreTheNewBaseline() {
        var table = EditableTableRows()
        table.load(complete, keys: keys, isStreaming: false)
        let rewritten: OpenUIValue = [["id": "1", "values": ["Apples", 9]], ["id": "2", "values": ["Pears", 5]]]

        table.load(rewritten, keys: keys, isStreaming: true)
        table.load(rewritten, keys: keys, isStreaming: false)

        #expect(table.changedCellCount(keys: keys) == 0)
        table.reset()
        #expect(table.rows[0]["qty"] == 9)

        table.rows[0]["qty"] = 4
        table.load(rewritten, keys: keys, isStreaming: false)
        #expect(table.changedCellCount(keys: keys) == 1, "reloading the same rows keeps an edit")
    }

    @Test func dataThatArrivesAfterStreamingIsTheNewBaseline() {
        var table = EditableTableRows()
        table.load([], keys: keys, isStreaming: false)
        table.load(complete, keys: keys, isStreaming: false)

        #expect(table.rows.count == 2)
        #expect(table.changedCellCount(keys: keys) == 0, "a Query's rows aren't edits")

        table.rows[0]["qty"] = 4
        #expect(table.changedCellCount(keys: keys) == 1)

        table.load([["id": "1", "values": ["Apples", 9]], ["id": "2", "values": ["Pears", 5]]], keys: keys, isStreaming: false)
        table.reset()

        #expect(table.rows[0]["qty"] == 9, "reset goes back to the latest data")
        #expect(table.changedCellCount(keys: keys) == 0)
    }

    @Test func datesReadAsNoonOfTheDay() throws {
        let date = try #require(DateFormatting.date(from: "2025-09-07"))

        #expect(Calendar(identifier: .gregorian).component(.hour, from: date) == 12)
        #expect(DateFormatting.string(from: date) == "2025-09-07")
        #expect(DateFormatting.date(from: "2025-02-30") == nil)
        #expect(DateFormatting.date(from: "") == nil)
        #expect(DateFormatting.date(from: "2025-09-07T10:00:00Z") != nil)
    }

    @Test func timesAreTheMomentTheyName() {
        let local = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2025, month: 9, day: 7, hour: 10))

        #expect(DateFormatting.date(from: "2025-09-07T23:30:00-05:00") == Date(timeIntervalSince1970: 1_757_305_800))
        #expect(DateFormatting.date(from: "2025-09-07T10:00:00") == local)
        #expect(DateFormatting.date(from: "2025-09-07xyz") == nil)
    }

    @Test func datesAndTimesReadAsInJavaScript() throws {
        let local = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 10, minute: 30))
        let utc = Date(timeIntervalSince1970: 1_705_314_600)

        for text in ["2024-01-15 10:30:00", "2024-01-15T10:30", "2024-01-15 10:30", "2024-01-15T10:30:00.000"] {
            #expect(DateFormatting.date(from: text) == local, "\(text)")
        }
        for text in ["2024-01-15T10:30:00.000Z", "2024-01-15 10:30:00Z", "2024-01-15t10:30:00z", "2024-01-15T12:30:00+0200", "2024-01-15T05:00-05:30"] {
            #expect(DateFormatting.date(from: text) == utc, "\(text)")
        }
        #expect(DateFormatting.date(from: "2024-01-15T10:30:00.5Z") == utc.addingTimeInterval(0.5))
        let milliseconds = try #require(DateFormatting.date(from: "2024-01-15T10:30:00.123456Z"))
        #expect(abs(milliseconds.timeIntervalSince(utc) - 0.123) < 0.0001, "JavaScript keeps milliseconds")
        for text in ["2024-01-15T", "2024-01-15T10:30+24:00", "2024-01-15T10:61"] {
            #expect(DateFormatting.date(from: text) == nil, "\(text)")
        }
    }

    @Test func rowsFollowTheColumns() {
        var table = EditableTableRows()
        table.load(complete, keys: ["name"], isStreaming: true)
        #expect(table.rows[0]["qty"] == nil)

        table.load(complete, keys: keys, isStreaming: true)
        #expect(table.rows[0]["qty"] == 3)
        #expect(EditableTableRows.rows(from: [["id": "3", "values": []]], keys: keys) == [["id": "3", "name": "", "qty": ""]])
    }
}
