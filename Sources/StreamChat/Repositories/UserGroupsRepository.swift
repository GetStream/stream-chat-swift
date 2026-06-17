//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A response containing a list of user groups.
struct UserGroupListResponse: Sendable {
    let userGroups: [UserGroup]
    let hasMore: Bool
}

/// Repository for handling user groups.
class UserGroupsRepository: @unchecked Sendable {
    private let database: DatabaseContainer
    private let apiClient: APIClient

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }

    func loadUserGroups(
        query: UserGroupListQuery,
        completion: @escaping @Sendable (Result<UserGroupListResponse, Error>) -> Void
    ) {
        apiClient.request(endpoint: .userGroups(query: query)) { [weak self] result in
            switch result {
            case .success(let response):
                self?.saveUserGroups(response.userGroups, expectedCount: query.limit, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func searchUserGroups(
        query: UserGroupSearchQuery,
        completion: @escaping @Sendable (Result<[UserGroup], Error>) -> Void
    ) {
        apiClient.request(endpoint: .searchUserGroups(query: query)) { result in
            switch result {
            case .success(let response):
                completion(.success(response.userGroups.map { $0.asModel() }))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func searchUserGroups(query: UserGroupSearchQuery) async throws -> [UserGroup] {
        try await withCheckedThrowingContinuation { continuation in
            searchUserGroups(query: query) { result in
                continuation.resume(with: result)
            }
        }
    }

    func loadUserGroup(
        id: String,
        teamId: String?,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        apiClient.request(endpoint: .getUserGroup(id: id, teamId: teamId)) { [weak self] result in
            switch result {
            case .success(let response):
                self?.saveUserGroup(response.userGroup, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createUserGroup(
        request: CreateUserGroupRequestBody,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        apiClient.request(endpoint: .createUserGroup(request: request)) { [weak self] result in
            switch result {
            case .success(let response):
                self?.saveUserGroup(response.userGroup, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateUserGroup(
        id: String,
        request: UpdateUserGroupRequestBody,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        apiClient.request(endpoint: .updateUserGroup(id: id, request: request)) { [weak self] result in
            switch result {
            case .success(let response):
                self?.saveUserGroup(response.userGroup, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteUserGroup(
        id: String,
        teamId: String?,
        completion: @escaping @Sendable (Error?) -> Void
    ) {
        apiClient.request(endpoint: .deleteUserGroup(id: id, teamId: teamId)) { [weak self] result in
            switch result {
            case .success:
                self?.database.write({ session in
                    session.deleteUserGroup(id: id)
                }, completion: { error in
                    completion(error)
                })
            case .failure(let error):
                completion(error)
            }
        }
    }

    func addMembers(
        id: String,
        request: UserGroupMembersRequestBody,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        apiClient.request(endpoint: .addUserGroupMembers(id: id, request: request)) { [weak self] result in
            switch result {
            case .success(let response):
                self?.saveUserGroup(response.userGroup, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func removeMembers(
        id: String,
        request: UserGroupMembersRequestBody,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        apiClient.request(endpoint: .removeUserGroupMembers(id: id, request: request)) { [weak self] result in
            switch result {
            case .success(let response):
                self?.saveUserGroup(response.userGroup, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func saveUserGroups(
        _ payloads: [UserGroupPayload],
        expectedCount: Int,
        completion: @escaping @Sendable (Result<UserGroupListResponse, Error>) -> Void
    ) {
        database.write(converting: { session in
            let userGroups = payloads.compactMap { payload -> UserGroup? in
                do {
                    return try session.saveUserGroup(payload: payload).asModel()
                } catch {
                    log.error("Failed to convert user group payload to model: \(error.localizedDescription)")
                    return nil
                }
            }
            return UserGroupListResponse(
                userGroups: userGroups,
                hasMore: payloads.count >= expectedCount
            )
        }, completion: completion)
    }

    private func saveUserGroup(
        _ payload: UserGroupPayload,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        database.write(converting: { session in
            try session.saveUserGroup(payload: payload).asModel()
        }, completion: completion)
    }
}
