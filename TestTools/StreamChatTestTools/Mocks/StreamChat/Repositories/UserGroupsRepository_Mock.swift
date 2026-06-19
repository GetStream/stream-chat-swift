//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of `UserGroupsRepository`.
final class UserGroupsRepository_Mock: UserGroupsRepository, @unchecked Sendable {
    var loadUserGroups_query: UserGroupListQuery?
    var loadUserGroups_completion_result: Result<UserGroupListResponse, Error>?

    var searchUserGroups_query: UserGroupSearchQuery?
    var searchUserGroups_completion_result: Result<[UserGroup], Error>?

    var loadUserGroup_id: String?
    var loadUserGroup_teamId: String?
    var loadUserGroup_completion_result: Result<UserGroup, Error>?

    var createUserGroup_request: CreateUserGroupRequestBody?
    var createUserGroup_completion_result: Result<UserGroup, Error>?

    var updateUserGroup_id: String?
    var updateUserGroup_request: UpdateUserGroupRequestBody?
    var updateUserGroup_completion_result: Result<UserGroup, Error>?

    var deleteUserGroup_id: String?
    var deleteUserGroup_teamId: String?
    var deleteUserGroup_error: Error?

    var addMembers_id: String?
    var addMembers_request: UserGroupMembersRequestBody?
    var addMembers_completion_result: Result<UserGroup, Error>?

    var removeMembers_id: String?
    var removeMembers_request: UserGroupMembersRequestBody?
    var removeMembers_completion_result: Result<UserGroup, Error>?

    override init(database: DatabaseContainer, apiClient: APIClient) {
        super.init(database: database, apiClient: apiClient)
    }

    init() {
        super.init(database: DatabaseContainer_Spy(), apiClient: APIClient_Spy())
    }

    override func loadUserGroups(
        query: UserGroupListQuery,
        completion: @escaping @Sendable (Result<UserGroupListResponse, Error>) -> Void
    ) {
        loadUserGroups_query = query
        if let result = loadUserGroups_completion_result {
            completion(result)
        }
    }

    override func searchUserGroups(
        query: UserGroupSearchQuery,
        completion: @escaping @Sendable (Result<[UserGroup], Error>) -> Void
    ) {
        searchUserGroups_query = query
        if let result = searchUserGroups_completion_result {
            completion(result)
        }
    }

    override func loadUserGroup(
        id: String,
        teamId: String?,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        loadUserGroup_id = id
        loadUserGroup_teamId = teamId
        if let result = loadUserGroup_completion_result {
            completion(result)
        }
    }

    override func createUserGroup(
        request: CreateUserGroupRequestBody,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        createUserGroup_request = request
        if let result = createUserGroup_completion_result {
            completion(result)
        }
    }

    override func updateUserGroup(
        id: String,
        request: UpdateUserGroupRequestBody,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        updateUserGroup_id = id
        updateUserGroup_request = request
        if let result = updateUserGroup_completion_result {
            completion(result)
        }
    }

    override func deleteUserGroup(
        id: String,
        teamId: String?,
        completion: @escaping @Sendable (Error?) -> Void
    ) {
        deleteUserGroup_id = id
        deleteUserGroup_teamId = teamId
        completion(deleteUserGroup_error)
    }

    override func addMembers(
        id: String,
        request: UserGroupMembersRequestBody,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        addMembers_id = id
        addMembers_request = request
        if let result = addMembers_completion_result {
            completion(result)
        }
    }

    override func removeMembers(
        id: String,
        request: UserGroupMembersRequestBody,
        completion: @escaping @Sendable (Result<UserGroup, Error>) -> Void
    ) {
        removeMembers_id = id
        removeMembers_request = request
        if let result = removeMembers_completion_result {
            completion(result)
        }
    }
}
