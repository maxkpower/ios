import BitwardenSdk
import Foundation

// MARK: - ItemListRoute

/// A route to a specific screen or subscreen of the Item List
public enum ItemListRoute: Equatable, Hashable {
    /// A route to the add item screen.
    case addItem

    /// A route to the base item list screen.
    case list

    /// A route to the manual totp screen for setting up TOTP.
    case setupTotpManual

    /// A route to the view item screen.
    ///
    /// - Parameter id: The id of the token to display.
    ///
    case viewItem(id: String)
}

enum ItemListEvent {
    /// When the app should show the scan code screen.
    ///  Defaults to `.setupTotpManual` if camera is unavailable.
    case showScanCode
}
