//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI
import UIKit

@MainActor
enum DemoScheduleMessagePicker {
    struct Preset {
        let title: String
        let date: Date
    }

    static func present(
        from presenter: UIViewController,
        title: String = "Schedule message",
        sourceView: UIView?,
        initialDate: Date? = nil,
        onSelect: @escaping (Date) -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: "All times in \(DemoScheduledDateFormatter.timeZoneDescription)",
            preferredStyle: .actionSheet
        )
        for preset in presets() {
            alert.addAction(UIAlertAction(title: preset.title, style: .default) { _ in
                onSelect(preset.date)
            })
        }
        alert.addAction(UIAlertAction(title: "Custom Time", style: .default) { [weak presenter] _ in
            guard let presenter else { return }
            let datePickerVC = UIHostingController(rootView: DemoScheduleDatePicker(initialDate: initialDate) { [weak presenter] date in
                presenter?.dismiss(animated: true) { date.map(onSelect) }
            })
            datePickerVC.sheetPresentationController?.prefersGrabberVisible = true
            presenter.present(datePickerVC, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let sourceView {
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        presenter.present(alert, animated: true)
    }

    static func presets(now: Date = Date(), calendar: Calendar = .current) -> [Preset] {
        var presets = [Preset(title: "In 2 minutes", date: now.addingTimeInterval(2 * 60))]

        guard
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
            let tomorrowMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
        else { return presets }
        presets.append(Preset(title: DemoScheduledDateFormatter.string(from: tomorrowMorning, now: now), date: tomorrowMorning))

        if let mondayMorning = calendar.nextDate(
            after: tomorrowMorning,
            matching: DateComponents(hour: 9, minute: 0, weekday: 2),
            matchingPolicy: .nextTime
        ) {
            presets.append(Preset(title: DemoScheduledDateFormatter.string(from: mondayMorning, now: now), date: mondayMorning))
        }
        return presets
    }
}

/// Picks a custom date, within the scheduling limits. Calls `onFinish` with `nil` when cancelled.
struct DemoScheduleDatePicker: View {
    let onFinish: (Date?) -> Void
    @State private var date: Date
    private let range: ClosedRange<Date>

    init(initialDate: Date?, onFinish: @escaping (Date?) -> Void) {
        let now = Date()
        range = now.addingTimeInterval(DemoScheduledMessageLimits.minimumLeadTime)...now
            .addingTimeInterval(DemoScheduledMessageLimits.maximumLeadTime)
        _date = State(initialValue: min(max(initialDate ?? now.addingTimeInterval(60 * 60), range.lowerBound), range.upperBound))
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("Custom Time", selection: $date, in: range)
                    .datePickerStyle(.graphical)
                    .tint(Color(Appearance.default.colorPalette.accentPrimary))
                Text("All times in \(DemoScheduledDateFormatter.timeZoneDescription)")
                    .font(.footnote)
                    .foregroundColor(Color(Appearance.default.colorPalette.textSecondary))
                Spacer()
            }
            .padding()
            .background(Color(Appearance.default.colorPalette.backgroundCoreApp))
            .navigationTitle("Custom Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onFinish(nil) } }
                ToolbarItem(placement: .confirmationAction) { Button("Schedule") { onFinish(date) } }
            }
        }
        .navigationViewStyle(.stack)
    }
}
