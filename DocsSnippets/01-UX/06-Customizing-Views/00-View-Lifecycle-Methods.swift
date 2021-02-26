// LINK: https://getstream.io/chat/docs/ios-swift/ios_styles/?preview=1&language=swift#view-lifecycle-methods

import StreamChatUI

func snippets_ux_customizing_views_view_lifecycle_methods() {
    // > import StreamChatUI

    class MyView: _View {
        /// Main point of customization for the view functionality.
        /// It's called zero or one time(s) during the view's
        /// lifetime. Calling super implementation is required.
        override func setUp() {}

        /// Main point of customization for the view appearance.
        /// It's called zero or one time(s) during the view's lifetime.
        /// The default implementation of this method is empty so calling `super` is usually not needed.
        override func setUpAppearance() {}

        /// Main point of customization for the view layout.
        /// It's called zero or one time(s) during the view's lifetime.
        /// Calling super is recommended but not required if you provide a complete layout for all subviews.
        override func setUpLayout() {}

        /// Main point of customization for the view appearance.
        /// It's called every time view's content changes.
        /// Calling super is recommended but not required
        /// if you update the content of all subviews of the view.
        override func updateContent() {}
    }
}
