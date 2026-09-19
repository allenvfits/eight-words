import Foundation

struct SupabaseConfiguration: Sendable {
    let projectURL: URL
    let publishableKey: String

    static var bundled: SupabaseConfiguration? {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseProjectURL") as? String,
            let projectURL = URL(string: urlString),
            projectURL.scheme == "https",
            let publishableKey = Bundle.main.object(forInfoDictionaryKey: "SupabasePublishableKey") as? String,
            !publishableKey.isEmpty,
            !urlString.contains("$("),
            !publishableKey.contains("$(")
        else {
            return nil
        }

        return SupabaseConfiguration(projectURL: projectURL, publishableKey: publishableKey)
    }
}
