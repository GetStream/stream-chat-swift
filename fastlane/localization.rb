# To run this script update `ios_repo_path` and `android_repo_path` variables and run `ruby localization.rb`

ios_repo_path = '/Users/alexeyalterpesotskiy/Code/stream/stream-chat-swift'
android_repo_path = '/Users/alexeyalterpesotskiy/Code/stream/stream-chat-android'

localization_keys = [
  { ios: '"channel.item.empty-messages"', android: '"stream_compose_message_list_empty_messages"' },
  { ios: '"channelList.empty.title"', android: '"channel_list_empty_title"' },
  { ios: '"channelList.empty.subtitle"', android: '"channel_list_empty_description"' },
  { ios: '"channelList.empty.button"', android: '"channel_list_start_chat"' },
  { ios: '"channelList.search"', android: '"stream_ui_search_input_hint"' },
  { ios: '"channelList.search.empty.subtitle"', android: '"stream_ui_search_results_empty"' },
  { ios: '"channelList.preview.voice.recording"', android: '"stream_ui_message_audio_reply_info"' },
  { ios: '"message.actions.inline-reply"', android: '"stream_compose_reply"' },
  { ios: '"message.actions.thread-reply"', android: '"stream_compose_thread_reply"' },
  { ios: '"message.actions.edit"', android: '"stream_compose_edit_message"' },
  { ios: '"message.actions.copy"', android: '"stream_compose_copy_message"' },
  { ios: '"message.actions.delete"', android: '"stream_compose_delete_message"' },
  { ios: '"message.actions.delete.confirmation-title"', android: '"stream_ui_message_list_delete_confirmation_title"' },
  { ios: '"message.actions.delete.confirmation-message"', android: '"stream_ui_message_list_delete_confirmation_message"' },
  { ios: '"message.actions.user-block"', android: '"stream_ui_message_list_block_user"' },
  { ios: '"message.actions.user-unmute"', android: '"stream_ui_message_list_unmute_user"' },
  { ios: '"message.actions.user-mute"', android: '"stream_ui_message_list_mute_user"' },
  { ios: '"message.actions.resend"', android: '"stream_ui_message_list_resend_message"' },
  { ios: '"message.actions.flag"', android: '"stream_ui_message_list_flag_message"' },
  { ios: '"message.actions.flag.confirmation-title"', android: '"stream_ui_message_list_flag_confirmation_title"' },
  { ios: '"message.actions.flag.confirmation-message"', android: '"stream_ui_message_list_flag_confirmation_message"' },
  { ios: '"message.actions.mark-unread"', android: '"stream_ui_message_list_mark_as_unread"' },
  { ios: '"message.moderation.title"', android: '"stream_ui_moderation_dialog_title"' },
  { ios: '"message.moderation.message"', android: '"stream_ui_moderation_dialog_description"' },
  { ios: '"message.moderation.resend"', android: '"stream_ui_moderation_dialog_send"' },
  { ios: '"message.moderation.edit"', android: '"stream_ui_moderation_dialog_edit"' },
  { ios: '"message.moderation.delete"', android: '"stream_ui_moderation_dialog_delete"' },
  { ios: '"message.title.online"', android: '"stream_ui_user_status_online"' },
  { ios: '"message.threads.reply"', android: '"stream_compose_thread_title"' },
  { ios: '"message.threads.replyWith"', android: '"stream_compose_thread_subtitle"' },
  { ios: '"message.translatedTo"', android: '"stream_compose_message_list_translated"' },
  { ios: '"message.only-visible-to-you"', android: '"stream_compose_only_visible_to_you"' },
  { ios: '"message.deleted-message-placeholder"', android: '"stream_compose_message_deleted"' },
  { ios: '"message.unsupported-attachment"', android: '"stream_ui_attachment_unsupported_attachment"' },
  { ios: '"attachment.max-count-exceeded"', android: '"stream_compose_message_composer_error_attachment_count"' },
  { ios: '"alert.actions.cancel"', android: '"stream_ui_message_list_delete_confirmation_negative_button"' },
  { ios: '"alert.actions.delete"', android: '"stream_ui_message_list_delete_confirmation_positive_button"' },
  { ios: '"alert.actions.flag"', android: '"stream_ui_message_list_flag_confirmation_positive_button"' },
  { ios: '"alert.actions.ok"', android: '"ok"' },
  { ios: '"composer.title.edit"', android: '"stream_compose_edit_message"' },
  { ios: '"composer.title.reply"', android: '"stream_compose_reply_to_message"' },
  { ios: '"composer.placeholder.messageDisabled"', android: '"stream_compose_cannot_send_messages_label"' },
  { ios: '"composer.checkmark.direct-message-reply"', android: '"stream_compose_message_composer_show_in_channel"' },
  { ios: '"composer.checkmark.channel-reply"', android: '"stream_ui_message_composer_send_to_channel"' },
  { ios: '"composer.picker.file"', android: '"stream_compose_quoted_message_file_tag"' },
  { ios: '"composer.picker.cancel"', android: '"stream_compose_cancel"' },
  { ios: '"composer.links-disabled.subtitle"', android: '"stream_ui_message_composer_sending_links_not_allowed"' },
  { ios: '"composer.quoted-message.giphy"', android: '"stream_compose_message_list_giphy_title"' },
  { ios: '"composer.suggestions.commands.header"', android: '"stream_compose_message_composer_instant_commands"' },
  { ios: '"you"', android: '"stream_compose_channel_list_you"' },
  { ios: '"recording.tip"', android: '"stream_ui_message_composer_hold_to_record"' },
  { ios: '"recording.slideToCancel"', android: '"stream_ui_message_composer_slide_to_cancel"' },
]

['es', 'fr', 'it' ].each do |lang|
  ios_strings_path = "#{ios_repo_path}/Sources/StreamChatUI/Resources/#{lang}.lproj/Localizable.strings"
  android_strings_path = "#{android_repo_path}/stream-chat-android/*/src/main/res/values-#{lang}"
  ios_content = File.read(ios_strings_path)

  Dir["#{android_strings_path}/*.xml"].each do |xml|
    puts "Exploring #{xml}"
    File.read(xml).each_line do |android_line|
      localization_keys.each do |loc|
        next unless android_line.include?(loc[:android])

        match = android_line.match(/>(.*?)</)
        next unless match

        localized_string = match[1]&.gsub(/"/, '')&.gsub(/'/, '')&.gsub(/\\/, '')&.gsub(/%1\$s/, '%@')
        non_localized_string = ''
        ios_content.each_line do |ios_line|
          next unless ios_line.include?(loc[:ios])

          match = ios_line.match(/=\s*"([^"]*)";/)
          if match
            non_localized_string = match[1]
            break
          end
        end

        ios_content.gsub!("= \"#{non_localized_string}\"", "= \"#{localized_string}\"")
      end
    end
  end

  File.write(ios_strings_path, ios_content)
end

# MISSING KEYS ON ANDROID

  # channel.item.search.in
  # message.threads.replyWith
  # channel.item.audio
  # channel.item.video
  # channelList.error.message
  # messageList.typingIndicator.typing-unknown
  # message.actions.user-unblock
  # message.moderation.title
  # message.title.offline
  # message.sending.attachment-uploading-failed
  # attachment.max-size-exceeded
  # composer.placeholder.slowMode
  # composer.placeholder.giphy
  # composer.picker.title
  # composer.picker.media
  # composer.picker.camera
  # composer.links-disabled.title
  # channel.item.photo
  # composer.quoted-message.photo
  # current-selection
  # dates.time-ago-seconds-plural
  # dates.time-ago-seconds-singular
  # dates.time-ago-minutes-singular
  # dates.time-ago-minutes-plural
  # dates.time-ago-hours-singular
  # dates.time-ago-hours-plural
  # dates.time-ago-days-singular
  # dates.time-ago-days-plural
  # dates.time-ago-weeks-singular
  # dates.time-ago-weeks-plural
  # dates.time-ago-months-singular
  # dates.time-ago-months-plural

# ALMOST SIMILAR KEYS ON ANDROID AND IOS

  # channel.name.and => stream_compose_message_list_header_typing_users
  # channel.name.andXMore => stream_compose_message_list_header_typing_users
  # channel.item.typing-singular => stream_ui_message_list_header_typing_users
  # channel.item.typing-plural => stream_ui_message_list_header_typing_users
  # message.title.group => stream_ui_channel_list_member_info
