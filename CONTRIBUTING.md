# Contributing to Stream Chat Swift SDK

We're glad you want to contribute to the Stream team 🎉

---

_So you..._

### Got stuck on something 💭

Please check [stackoverflow](https://stackoverflow.com/questions/tagged/getstream-io) and ask your questions there.
If your question is not generic, you can send us a [support request](https://getstream.io/support).

### Found a bug 🐞

Please create a github issue with as much info as possible (follow the Issue Template closely).

### Have a feature request 📈

Please create a github issue with as much info as possible.

### Fixed a bug 🩹

Please open a PR with as much info as possible: clear description of the problem and the solution.
Include the relevant github issue number if applicable. 

Make sure Changelog is updated correspondingly (we'll probably change wording but it'll help us immensely)

Before submitting, please make sure you're finished with the PR (and all tests pass) and do not make changes until it's reviewed.

### Implemented or changed a feature 🌈

Guidelines on "Fixed a bug" part is applicable.

## Our Release flow 🚀

We make sure to follow all QA test procedure for minor and major releases. 

We accumulate changes and release them in batches, unless high priority.
We make sure to put staged changes (on default branch but not released in a version) as "Upcoming" in [CHANGELOG](https://github.com/GetStream/stream-chat-swift/blob/main/CHANGELOG.md).

If possible, we deprecate stuff before removing them directly. Deprecated stuff will be removed after a minor release, and will include a migration/upgrade guide.
