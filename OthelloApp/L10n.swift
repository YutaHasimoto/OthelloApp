import Foundation

enum L10n {
    static func string(_ key: String, bundle: Bundle = .main) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        format(key, arguments: arguments, bundle: .main)
    }

    static func format(_ key: String, arguments: [CVarArg], bundle: Bundle) -> String {
        String(format: string(key, bundle: bundle), locale: Locale.current, arguments: arguments)
    }

    static func bundle(for localeIdentifier: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: localeIdentifier, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }
}
