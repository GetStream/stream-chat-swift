//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI
import UIKit

class UserProfileViewController: UITableViewController, CurrentChatUserControllerDelegate {
    private let imageView = UIImageView()
    private let updateButton = UIButton()

    var name: String?
    let properties = UserProperty.allCases

    enum UserProperty: CaseIterable {
        case name
        case role
        case typingIndicatorsEnabled
        case readReceiptsEnabled
        case detailedUnreadCounts
    }

    let currentUserController: CurrentChatUserController

    init(currentUserController: CurrentChatUserController) {
        self.currentUserController = currentUserController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = false
        view.backgroundColor = .systemBackground

        [imageView, updateButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        tableView.tableHeaderView = UIView(frame: .init(origin: .zero, size: .init(width: .zero, height: 80)))
        tableView.tableHeaderView?.addSubview(imageView)
        tableView.tableFooterView = UIView(frame: .init(origin: .zero, size: .init(width: .zero, height: 80)))
        tableView.tableFooterView?.addSubview(updateButton)

        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        updateButton.setTitle("Update", for: .normal)
        updateButton.layer.cornerRadius = 4
        updateButton.backgroundColor = .systemBlue
        updateButton.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 15, bottom: 0.0, right: 15)
        updateButton.addTarget(self, action: #selector(didTapUpdateButton), for: .touchUpInside)
        updateButton.isHidden = !StreamRuntimeCheck.isStreamInternalConfiguration

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updateButton.heightAnchor.constraint(equalToConstant: 35),
            updateButton.centerYAnchor.constraint(equalTo: updateButton.superview!.centerYAnchor)
        ])

        currentUserController.delegate = self
        synchronizeAndUpdateData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        properties.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        switch properties[indexPath.row] {
        case .name:
            cell.textLabel?.text = "Name"
            cell.detailTextLabel?.text = name ?? currentUserController.currentUser?.name
            let button = UIButton(type: .detailDisclosure, primaryAction: UIAction(handler: { _ in
                self.presentAlert(title: "Name", textFieldPlaceholder: self.currentUserController.currentUser?.name) { newValue in
                    self.name = newValue
                    self.updateUserData()
                }
            }))
            button.setImage(.init(systemName: "pencil"), for: .normal)
            cell.accessoryView = button
        case .role:
            let role = currentUserController.currentUser?.userRole
            let isAdmin = role == UserRole.admin
            cell.textLabel?.text = "User Role"
            cell.detailTextLabel?.text = role?.rawValue ?? "<unknown>"
            cell.accessoryView = makeButton(title: isAdmin ? "Downgrade" : "Upgrade", action: { [weak currentUserController] in
                currentUserController?.updateUserData(role: isAdmin ? .user : .admin)
            })
        case .readReceiptsEnabled:
            cell.textLabel?.text = "Read Receipts Enabled"
            cell.accessoryView = makeSwitchButton(UserConfig.shared.readReceiptsEnabled ?? true) { newValue in
                UserConfig.shared.readReceiptsEnabled = newValue
            }
        case .typingIndicatorsEnabled:
            cell.textLabel?.text = "Typing Indicators Enabled"
            cell.accessoryView = makeSwitchButton(UserConfig.shared.typingIndicatorsEnabled ?? true) { newValue in
                UserConfig.shared.typingIndicatorsEnabled = newValue
            }
        case .detailedUnreadCounts:
            cell.textLabel?.text = "Detailed Unread Counts"
            cell.accessoryView = makeButton(title: "View Details", action: { [weak self] in
                self?.showDetailedUnreads()
            })
        }
        return cell
    }

    private func synchronizeAndUpdateData() {
        currentUserController.synchronize()
        updateUserData()
    }

    private func updateUserData() {
        guard let imageURL = currentUserController.currentUser?.imageURL else { return }
        DispatchQueue.global().async { [weak self] in
            guard let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }

        if let typingIndicatorsEnabled = currentUserController.currentUser?.privacySettings.typingIndicators?.enabled {
            UserConfig.shared.typingIndicatorsEnabled = typingIndicatorsEnabled
        }
        if let readReceiptsEnabled = currentUserController.currentUser?.privacySettings.readReceipts?.enabled {
            UserConfig.shared.readReceiptsEnabled = readReceiptsEnabled
        }

        tableView.reloadData()
    }

    private func showDetailedUnreads() {
        let unreadDetailsView = UnreadDetailsView(
            onLoadData: { [weak self](completion: @escaping (Result<CurrentUserUnreads, Error>) -> Void) in
                self?.currentUserController.loadAllUnreads { result in
                    DispatchQueue.main.async {
                        completion(result)
                    }
                }
            },
            onDismiss: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
        let hostingController = UIHostingController(rootView: unreadDetailsView)
        hostingController.title = "Unread Details"
        
        present(hostingController, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func didTapUpdateButton() {
        currentUserController.updateUserData(
            name: name,
            privacySettings: .init(
                typingIndicators: UserConfig.shared.typingIndicatorsEnabled.map { .init(enabled: $0) },
                readReceipts: UserConfig.shared.readReceiptsEnabled.map { .init(enabled: $0) }
            )
        )
    }

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>) {
        name = controller.currentUser?.name
        updateUserData()
    }

    private func makeSwitchButton(_ initialValue: Bool, _ didChangeValue: @escaping (Bool) -> Void) -> SwitchButton {
        let switchButton = SwitchButton()
        switchButton.isOn = initialValue
        switchButton.didChangeValue = didChangeValue
        return switchButton
    }

    private func makeButton(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addAction(UIAction(handler: { _ in action() }), for: .touchUpInside)
        button.sizeToFit()
        return button
    }
}

// MARK: - SwiftUI Views

struct UnreadDetailsView: View {
    let onLoadData: (@escaping (Result<CurrentUserUnreads, Error>) -> Void) -> Void
    let onDismiss: () -> Void
    
    @State private var unreads: CurrentUserUnreads?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading unread data...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadData()
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let unreads = unreads {
                    List {
                        // Summary Section
                        Section(header: Text("Summary")) {
                            SummaryRow(title: "Total Unread Messages", value: "\(unreads.totalUnreadMessagesCount)")
                            SummaryRow(title: "Total Unread Channels", value: "\(unreads.totalUnreadChannelsCount)")
                            SummaryRow(title: "Total Unread Threads", value: "\(unreads.totalUnreadThreadsCount)")
                        }
                        
                        // Unread Channels Section
                        Section(header: Text("Unread Channels (\(unreads.unreadChannels.count))")) {
                            ForEach(unreads.unreadChannels, id: \.channelId.rawValue) { channel in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(channel.channelId.id)
                                            .font(.headline)
                                        Spacer()
                                        Text("\(channel.unreadMessagesCount)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    
                                    if let lastRead = channel.lastRead {
                                        Text("Last read: \(dateFormatter.string(from: lastRead))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Never read")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        
                        // Unread Threads Section
                        Section(header: Text("Unread Threads (\(unreads.unreadThreads.count))")) {
                            ForEach(unreads.unreadThreads, id: \.parentMessageId) { thread in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Thread: \(thread.parentMessageId)")
                                            .font(.headline)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(thread.unreadRepliesCount)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    
                                    if let lastRead = thread.lastRead {
                                        Text("Last read: \(dateFormatter.string(from: lastRead))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Never read")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let lastReadMessageId = thread.lastReadMessageId {
                                        Text("Last read message: \(lastReadMessageId)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        
                        // Channel Types Section
                        Section(header: Text("Unread by Channel Type")) {
                            ForEach(unreads.unreadChannelsByType, id: \.channelType.rawValue) { typeInfo in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(typeInfo.channelType.rawValue.capitalized)
                                            .font(.headline)
                                        Text("\(typeInfo.unreadChannelCount) channels")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("\(typeInfo.unreadMessagesCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                .padding(.vertical, 2)
                            }
                        }

                        // Unread by Team Section
                        let teamUnreads = unreads.totalUnreadCountByTeam ?? [:]
                        Section(header: Text("Unread by Team (\(teamUnreads.count))")) {
                            ForEach(Array(teamUnreads.keys).sorted(), id: \.self) { teamId in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Team: \(teamId)")
                                            .font(.headline)
                                        Text("Team ID: \(teamId)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("\(teamUnreads[teamId] ?? 0)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Unread Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: loadData) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                    }
                }
                .disabled(isLoading),
                trailing: Button("Done") {
                    onDismiss()
                }
            )
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        onLoadData { result in
            isLoading = false
            
            switch result {
            case .success(let unreadData):
                unreads = unreadData
                errorMessage = nil
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}
