//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

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
        let endpoint: Endpoint<ListUserGroupsResponse> = .listUserGroups(
            limit: query.limit,
            idGt: query.idGreaterThan,
            createdAtGt: query.createdAtGreaterThan.map { RFC3339DateFormatter.string(from: $0) },
            teamId: query.teamId
        )
        apiClient.request(endpoint: endpoint) { [weak self] result in
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
        let endpoint: Endpoint<ListUserGroupsResponse> = .searchUserGroups(
            query: query.query,
            limit: query.limit,
            nameGt: query.nameGreaterThan,
            idGt: query.idGreaterThan,
            teamId: query.teamId
        )
        apiClient.request(endpoint: endpoint) { result in
            switch result {
            case .success(let response):
                completion(.success(response.userGroups))
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
        request: CreateUserGroupRequest,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        apiClient.request(endpoint: .createUserGroup(createUserGroupRequest: request)) { [weak self] result in
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
        request: UpdateUserGroupRequest,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        apiClient.request(endpoint: .updateUserGroup(id: id, updateUserGroupRequest: request)) { [weak self] result in
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
        request: AddUserGroupMembersRequest,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        apiClient.request(endpoint: .addUserGroupMembers(id: id, addUserGroupMembersRequest: request)) { [weak self] result in
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
        request: RemoveUserGroupMembersRequest,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        apiClient.request(endpoint: .removeUserGroupMembers(id: id, removeUserGroupMembersRequest: request)) { [weak self] result in
            switch result {
            case .success(let response):
                self?.saveUserGroup(response.userGroup, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func saveUserGroups(
        _ userGroups: [UserGroup],
        expectedCount: Int?,
        completion: @escaping @Sendable (Result<UserGroupListResponse, Error>) -> Void
    ) {
        database.write(converting: { session in
            let savedUserGroups = userGroups.compactMap { userGroup -> UserGroup? in
                do {
                    return try session.saveUserGroup(payload: userGroup).asModel()
                } catch {
                    log.error("Failed to save user group to the database: \(error.localizedDescription)")
                    return nil
                }
            }
            let hasMore: Bool
            if let expectedCount {
                hasMore = userGroups.count >= expectedCount
            } else {
                hasMore = !userGroups.isEmpty
            }
            return UserGroupListResponse(
                userGroups: savedUserGroups,
                hasMore: hasMore
            )
        }, completion: completion)
    }

    private func saveUserGroup(
        _ userGroup: UserGroup?,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        guard let userGroup else {
            completion(.failure(ClientError.Unexpected("Missing `user_group` in the user group response.")))
            return
        }
        database.write(converting: { session in
            try session.saveUserGroup(payload: userGroup).asModel()
        }, completion: completion)
    }
}
