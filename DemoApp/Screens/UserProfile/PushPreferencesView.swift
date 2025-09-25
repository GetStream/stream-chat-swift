//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 15, *)
struct PushPreferencesView: View {
    let onSetPreferences: (PushPreferenceLevel, @escaping (Result<PushPreferenceLevel, Error>) -> Void) -> Void
    let onDisableNotifications: (Date, @escaping (Result<PushPreferenceLevel, Error>) -> Void) -> Void
    let onDismiss: () -> Void

    @State private var selectedLevel: PushPreferenceLevel = .all
    @State private var disableUntil: Date?
    @State private var isLoading = false
    @State private var showSuccessMessage = false
    @State private var errorMessage: String?
    @State private var showDatePicker = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notification Level")) {
                    ForEach([PushPreferenceLevel.all, .mentions, .none], id: \.rawValue) { level in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(levelTitle(for: level))
                                    .font(.headline)
                                Text(levelDescription(for: level))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLevel = level
                        }
                    }
                }

                Section(header: Text("Temporary Disable")) {
                    Toggle("Disable notifications temporarily", isOn: Binding(
                        get: { disableUntil != nil },
                        set: { isEnabled in
                            if isEnabled {
                                // Set to 1 hour from now by default
                                disableUntil = Date().addingTimeInterval(3600)
                            } else {
                                disableUntil = nil
                            }
                        }
                    ))

                    if let disableUntil = disableUntil {
                        HStack {
                            Text("Disable until:")
                            Spacer()
                            Button(dateFormatter.string(from: disableUntil)) {
                                showDatePicker = true
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }

                Section {
                    Button(action: savePreferences) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                            Text("Save Preferences")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading)
                    .foregroundColor(.white)
                    .listRowBackground(Color.blue)
                }
                
                if disableUntil != nil {
                    Section {
                        Button(action: disableNotifications) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "bell.slash")
                                }
                                Text("Disable Notifications")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(isLoading)
                        .foregroundColor(.white)
                        .listRowBackground(Color.orange)
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Push Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDismiss()
                },
                trailing: Button("Save") {
                    savePreferences()
                }
                .disabled(isLoading)
            )
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    DatePicker(
                        "Disable until",
                        selection: Binding(
                            get: { disableUntil ?? Date() },
                            set: { disableUntil = $0 }
                        ),
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showDatePicker = false
                        },
                        trailing: Button("Done") {
                            showDatePicker = false
                        }
                    )
                }
            }
            .alert("Success", isPresented: $showSuccessMessage) {
                Button("OK") {
                    onDismiss()
                }
            } message: {
                Text("Push preferences have been updated successfully.")
            }
        }
    }

    private func levelTitle(for level: PushPreferenceLevel) -> String {
        switch level {
        case .all:
            return "All Notifications"
        case .mentions:
            return "Mentions Only"
        case .none:
            return "No Notifications"
        default:
            return level.rawValue.capitalized
        }
    }

    private func levelDescription(for level: PushPreferenceLevel) -> String {
        switch level {
        case .all:
            return "Receive notifications for all messages"
        case .mentions:
            return "Only receive notifications when mentioned"
        case .none:
            return "Disable all push notifications"
        default:
            return "Custom notification level"
        }
    }

    private func savePreferences() {
        isLoading = true
        errorMessage = nil

        onSetPreferences(selectedLevel) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success:
                    showSuccessMessage = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func disableNotifications() {
        guard let disableUntil = disableUntil else { return }
        
        isLoading = true
        errorMessage = nil

        onDisableNotifications(disableUntil) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success:
                    // Dismiss the screen immediately when disabling notifications
                    onDismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
