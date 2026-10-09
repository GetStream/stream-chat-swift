//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
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
            let datePickerVC = DemoScheduleDatePickerVC(initialDate: initialDate, onSelect: onSelect)
            let navigationVC = UINavigationController(rootViewController: datePickerVC)
            navigationVC.modalPresentationStyle = .pageSheet
            navigationVC.sheetPresentationController?.detents = [.large()]
            navigationVC.sheetPresentationController?.prefersGrabberVisible = true
            presenter.present(navigationVC, animated: true)
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

final class DemoScheduleDatePickerVC: UIViewController {
    private let initialDate: Date?
    private let onSelect: (Date) -> Void
    private let datePicker = UIDatePicker()
    private let timeZoneLabel = UILabel()

    private var colors: Appearance.ColorPalette { Appearance.default.colorPalette }

    init(initialDate: Date?, onSelect: @escaping (Date) -> Void) {
        self.initialDate = initialDate
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Custom Time"
        view.backgroundColor = colors.backgroundCoreApp
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Schedule",
            style: .done,
            target: self,
            action: #selector(scheduleTapped)
        )

        let now = Date()
        let minimumDate = now.addingTimeInterval(DemoScheduledMessagesService.minimumLeadTime)
        let maximumDate = now.addingTimeInterval(DemoScheduledMessagesService.maximumLeadTime)
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .inline
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate
        datePicker.tintColor = colors.accentPrimary
        datePicker.date = min(max(initialDate ?? now.addingTimeInterval(60 * 60), minimumDate), maximumDate)

        timeZoneLabel.text = "All times in \(DemoScheduledDateFormatter.timeZoneDescription)"
        timeZoneLabel.font = .preferredFont(forTextStyle: .footnote)
        timeZoneLabel.adjustsFontForContentSizeCategory = true
        timeZoneLabel.textColor = colors.textSecondary
        timeZoneLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [datePicker, timeZoneLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func scheduleTapped() {
        let date = datePicker.date
        let onSelect = onSelect
        dismiss(animated: true) {
            onSelect(date)
        }
    }
}
