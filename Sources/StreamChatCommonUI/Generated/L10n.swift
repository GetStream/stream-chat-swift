// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation
import StreamCore


// MARK: - Strings

internal enum L10n {

  internal enum Channel {
    internal enum Name {
      /// and
      internal static var and: String { L10n.tr("Localizable", "channel.name.and") }
      /// and %@ more
      internal static func andXMore(_ p1: Any) -> String {
        return L10n.tr("Localizable", "channel.name.andXMore", String(describing: p1))
      }
    }
  }

  internal enum Dates {
    /// last seen %d days ago
    internal static func timeAgoDaysPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-days-plural", p1)
    }
    /// last seen one day ago
    internal static var timeAgoDaysSingular: String { L10n.tr("Localizable", "dates.time-ago-days-singular") }
    /// last seen %d hours ago
    internal static func timeAgoHoursPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-hours-plural", p1)
    }
    /// last seen one hour ago
    internal static var timeAgoHoursSingular: String { L10n.tr("Localizable", "dates.time-ago-hours-singular") }
    /// last seen %d minutes ago
    internal static func timeAgoMinutesPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-minutes-plural", p1)
    }
    /// last seen one minute ago
    internal static var timeAgoMinutesSingular: String { L10n.tr("Localizable", "dates.time-ago-minutes-singular") }
    /// last seen %d months ago
    internal static func timeAgoMonthsPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-months-plural", p1)
    }
    /// last seen one month ago
    internal static var timeAgoMonthsSingular: String { L10n.tr("Localizable", "dates.time-ago-months-singular") }
    /// last seen %d seconds ago
    internal static func timeAgoSecondsPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-seconds-plural", p1)
    }
    /// last seen just one second ago
    internal static var timeAgoSecondsSingular: String { L10n.tr("Localizable", "dates.time-ago-seconds-singular") }
    /// last seen %d weeks ago
    internal static func timeAgoWeeksPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "dates.time-ago-weeks-plural", p1)
    }
    /// last seen one week ago
    internal static var timeAgoWeeksSingular: String { L10n.tr("Localizable", "dates.time-ago-weeks-singular") }
  }

  internal enum Polls {
    internal enum Date {
      /// %dd ago
      internal static func daysAgo(_ p1: Int) -> String {
        return L10n.tr("Localizable", "polls.date.days-ago", p1)
      }
      /// %dw ago
      internal static func weeksAgo(_ p1: Int) -> String {
        return L10n.tr("Localizable", "polls.date.weeks-ago", p1)
      }
    }
  }

  internal enum Recording {
    internal enum Presentation {
      /// Plural format key: "%#@recording@"
      internal static func name(_ p1: Int) -> String {
        return L10n.tr("Localizable", "recording.presentation.name", p1)
      }
    }
  }
}

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
     // TODO: Using using Appearance.default prohibits using Appearance injection
     let format = StreamConcurrency.onMain {
       Appearance.default.localizationProvider(key, table)
     }
     return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {
  static let bundle: Bundle = .streamChatCommonUI
}

