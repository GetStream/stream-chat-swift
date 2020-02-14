# Make it more obvious that a PR is a work in progress and shouldn't be merged yet.
has_wip_label = github.pr_labels.any? { |label| label.include? "WIP" }
has_wip_title = github.pr_title.include? "[WIP]"

if has_wip_label || has_wip_title
    warn("PR is classed as Work in Progress")
end

# Warn when there is a big PR.
warn("Big PR") if git.lines_of_code > 500

# Mainly to encourage writing up some reasoning about the PR, rather than just leaving a title.
if github.pr_body.length < 3 && git.lines_of_code > 10
    warn("Please provide a summary in the Pull Request description")
end

## Let's check if there are any changes in the project folder
has_app_changes = !git.modified_files.grep(/Sources/).empty?
## Then, we should check if tests are updated
has_test_changes = !git.modified_files.grep(/StreamChatCoreTests/).empty?

has_changelog_escape = github.pr_body.include? "#no_changelog"

# Add a CHANGELOG entry for app changes
if !has_changelog_escape && !git.modified_files.include?("CHANGELOG.md") && has_app_changes
    fail("Please include a CHANGELOG entry. \nYou can find it at [CHANGELOG.md](https://github.com/GetStream/stream-chat-swift/blob/master/CHANGELOG.md).")
end

## Finally, let's combine them and put extra condition 
## for changed number of lines of code
if has_app_changes && !has_test_changes && git.lines_of_code > 20
    warn("Tests were not updated", sticky: false)
end

swiftlint.config_file = '.swiftlint.yml'
swiftlint.directory = 'Sources'
swiftlint.lint_files inline_mode: true
