skip_danger_check = github.pr_body.include? "#skip_danger"

if skip_danger_check
    message("Skipping Danger due to skip_danger tag")
    return
end

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet.
has_wip_label = github.pr_labels.any? { |label| label.include? "WIP" }
has_wip_title = github.pr_title.include? "[WIP]"

if has_wip_label || has_wip_title
    message("Skipping Danger since PR is classed as Work in Progress")
    return
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

has_meta_label = github.pr_labels.any? { |label| label.include? "meta" }
has_no_changelog_tag = github.pr_body.include? "#no_changelog"
has_skip_changelog_tag = github.pr_body.include? "#skip_changelog"
has_v3_label = github.pr_labels.any? { |label| label.include? "v3" }

has_changelog_escape = has_meta_label || has_no_changelog_tag || has_skip_changelog_tag || has_v3_label

# Add a CHANGELOG entry for app changes
if !has_changelog_escape && !git.modified_files.include?("CHANGELOG.md") && has_app_changes
    fail("Please include a CHANGELOG entry. \nYou can find it at [CHANGELOG.md](https://github.com/GetStream/stream-chat-swift/blob/master/CHANGELOG.md).")
end

# Check all commits have correct format. Disable the length rule, since it's hardcoded
# to 50 and GitHub has the limit 80.
commit_lint.check disable: [:subject_length]

swiftlint.config_file = '.swiftlint.yml'
swiftlint.directory = 'Sources'
swiftlint.lint_files inline_mode: true
