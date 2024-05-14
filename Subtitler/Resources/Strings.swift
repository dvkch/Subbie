// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Action {
    /// Add line
    internal static let addLine = L10n.tr("Localizable", "action.add_line", fallback: "Add line")
    /// Localizable.strings
    ///   Amby
    /// 
    ///   Created by syan on 29/03/2024.
    internal static let cancel = L10n.tr("Localizable", "action.cancel", fallback: "Cancel")
    /// Close
    internal static let close = L10n.tr("Localizable", "action.close", fallback: "Close")
    /// Delay
    internal static let delay = L10n.tr("Localizable", "action.delay", fallback: "Delay")
    /// Move line
    internal static let moveLine = L10n.tr("Localizable", "action.move_line", fallback: "Move line")
    /// Offset all lines
    internal static let offsetAllLines = L10n.tr("Localizable", "action.offset_all_lines", fallback: "Offset all lines")
    /// Remove line
    internal static let removeLine = L10n.tr("Localizable", "action.remove_line", fallback: "Remove line")
    /// Update text
    internal static let updateText = L10n.tr("Localizable", "action.update_text", fallback: "Update text")
    /// Update timings
    internal static let updateTimings = L10n.tr("Localizable", "action.update_timings", fallback: "Update timings")
  }
  internal enum Contact {
    /// contact@syan.me
    internal static let address = L10n.tr("Localizable", "contact.address", fallback: "contact@syan.me")
    /// Copy email address to pasteboard
    internal static let copy = L10n.tr("Localizable", "contact.copy", fallback: "Copy email address to pasteboard")
    /// About Amby %@ (%@)
    internal static func subject(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "contact.subject", String(describing: p1), String(describing: p2), fallback: "About Amby %@ (%@)")
    }
    /// Choose your messaging app
    internal static let title = L10n.tr("Localizable", "contact.title", fallback: "Choose your messaging app")
  }
  internal enum Dialog {
    internal enum DelaySubtitles {
      /// Use a minus (-) sign for a negative offset and a dot (.) as decimal separator
      internal static let subtitle = L10n.tr("Localizable", "dialog.delay_subtitles.subtitle", fallback: "Use a minus (-) sign for a negative offset and a dot (.) as decimal separator")
      /// Input a delay in seconds to offset all lines in this subtitles
      internal static let title = L10n.tr("Localizable", "dialog.delay_subtitles.title", fallback: "Input a delay in seconds to offset all lines in this subtitles")
    }
    internal enum OpenVideo {
      /// Open video file
      internal static let title = L10n.tr("Localizable", "dialog.open_video.title", fallback: "Open video file")
    }
  }
  internal enum Error {
    /// Invalid file type: %@
    internal static func invalidFileType(_ p1: Any) -> String {
      return L10n.tr("Localizable", "error.invalid_file_type", String(describing: p1), fallback: "Invalid file type: %@")
    }
    /// Invalid timings format: %@
    internal static func invalidTimingsFormat(_ p1: Any) -> String {
      return L10n.tr("Localizable", "error.invalid_timings_format", String(describing: p1), fallback: "Invalid timings format: %@")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
