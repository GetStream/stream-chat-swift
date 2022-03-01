//
//  UserListDataSource.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 25/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public class UserListDataSource: NSObject {
    let viewModel: UserListViewModel
    init(viewModel: UserListViewModel) {
        self.viewModel = viewModel
    }
//    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.viewModel.getUsers(section: section).count
//    }
//    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        return self.viewModel.configureCell(tableView: tableView, indexPath: indexPath)
//    }
}
