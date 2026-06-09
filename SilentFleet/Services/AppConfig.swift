import Foundation

/// App-wide configuration constants. Replace placeholder values before shipping.
enum AppConfig {
    /// IMPORTANT: this key is safe to ship in the binary (it's the public key),
    static let revenueCatAPIKey = "appl_jzehSJkLZWVVkUNjFjQMhuoGKlb"

    // MARK: - Legal / Support URLs
    //
    // Replace with real hosted pages before App Store submission. The privacy
    // policy URL must also be entered in App Store Connect → App Information.

    static let privacyPolicyURL = URL(string: "https://example.com/silentfleet/privacy")!
    static let termsOfServiceURL = URL(string: "https://example.com/silentfleet/terms")!
    static let supportURL = URL(string: "https://example.com/silentfleet/support")!
}
