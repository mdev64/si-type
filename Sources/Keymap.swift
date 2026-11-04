import Foundation

/// A key-sequence → Sinhala lookup table loaded from a `.strings` resource.
///
/// A value ending in `#` means "commit immediately" instead of keeping the
/// sequence open for further composition.
struct Keymap {
    let entries: [String: String]

    static let phonetic = Keymap(resource: "phonetic")
    static let wijesekara = Keymap(resource: "wijesekara")

    init(resource: String) {
        if let url = Bundle.main.url(forResource: resource, withExtension: "strings"),
           let dict = NSDictionary(contentsOf: url) as? [String: String] {
            entries = dict
        } else {
            NSLog("SiType: could not load keymap \(resource)")
            entries = [:]
        }
    }

    func lookup(_ key: String) -> String? {
        entries[key]
    }
}

extension String {
    var commitsImmediately: Bool { hasSuffix("#") }
    var withoutCommitMarker: String { replacingOccurrences(of: "#", with: "") }
}
