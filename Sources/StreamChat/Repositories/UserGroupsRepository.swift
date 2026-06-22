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
        let endpoint: Endpoint<ListUserGroupsResponse> = .listUserGroups(
            limit: query.limit,
            idGt: query.idGreaterThan,
            createdAtGt: query.createdAtGreaterThan.flatMap(Self.queryString(from:)),
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
        let endpoint: Endpoint<SearchUserGroupsResponse> = .searchUserGroups(
            query: query.query,
            limit: query.limit,
            nameGt: query.nameGreaterThan,
            idGt: query.idGreaterThan,
            teamId: query.teamId
        )
        apiClient.request(endpoint: endpoint) { result in
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
                guard let userGroup = response.userGroup else {
                    completion(.failure(ClientError.Unexpected("The response did not contain a user group.")))
                    return
                }
                self?.saveUserGroup(userGroup, completion: completion)
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
                guard let userGroup = response.userGroup else {
                    completion(.failure(ClientError.Unexpected("The response did not contain a user group.")))
                    return
                }
                self?.saveUserGroup(userGroup, completion: completion)
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
                guard let userGroup = response.userGroup else {
                    completion(.failure(ClientError.Unexpected("The response did not contain a user group.")))
                    return
                }
                self?.saveUserGroup(userGroup, completion: completion)
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
                guard let userGroup = response.userGroup else {
                    completion(.failure(ClientError.Unexpected("The response did not contain a user group.")))
                    return
                }
                self?.saveUserGroup(userGroup, completion: completion)
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
                guard let userGroup = response.userGroup else {
                    completion(.failure(ClientError.Unexpected("The response did not contain a user group.")))
                    return
                }
                self?.saveUserGroup(userGroup, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Encodes a `Date` the same way it is serialized into a query parameter, so the
    /// resulting string matches the format the backend expects (e.g. for `created_at_gt`).
    private static func queryString(from date: Date) -> String? {
        guard let data = try? JSONEncoder.stream.encode(["date": date]),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let value = json["date"] else {
            return nil
        }
        return String(describing: value)
    }

    private func saveUserGroups(
        _ responses: [UserGroupResponse],
        expectedCount: Int?,
        completion: @escaping @Sendable (Result<UserGroupListResponse, Error>) -> Void
    ) {
        database.write(converting: { session in
            let userGroups = responses.compactMap { response -> UserGroup? in
                do {
                    return try session.saveUserGroup(response).asModel()
                } catch {
                    log.error("Failed to convert user group response to model: \(error.localizedDescription)")
                    return nil
                }
            }
            let hasMore: Bool
            if let expectedCount {
                hasMore = responses.count >= expectedCount
            } else {
                hasMore = !responses.isEmpty
            }
            return UserGroupListResponse(
                userGroups: userGroups,
                hasMore: hasMore
            )
        }, completion: completion)
    }

    private func saveUserGroup(
        _ response: UserGroupResponse,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        database.write(converting: { session in
            try session.saveUserGroup(response).asModel()
        }, completion: completion)
    }
}
