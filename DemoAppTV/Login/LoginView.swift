//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct LoginView: View {
    let client: ChatClient
    let onLogin: (UserId) -> Void

    private let users = UserCredentials.builtInUsers
    @State private var connectingUserId: UserId?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(users, id: \.id) { user in
                        Button {
                            logIn(as: user)
                        } label: {
                            HStack(spacing: 24) {
                                AvatarView(url: user.avatarURL)
                                Text(user.name)
                                Spacer()
                                if connectingUserId == user.id {
                                    ProgressView()
                                }
                            }
                        }
                    }
                } footer: {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .disabled(connectingUserId != nil)
            .navigationTitle("Choose a User")
        }
    }

    private func logIn(as user: UserCredentials) {
        connectingUserId = user.id
        errorMessage = nil
        Task {
            defer { connectingUserId = nil }
            do {
                try await client.connectUser(userInfo: user.userInfo, token: user.token)
                onLogin(user.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
