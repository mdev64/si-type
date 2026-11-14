import Foundation

/// A key-sequence → Sinhala lookup table loaded from a `.strings` resource.
///
/// A value ending in `#` means "commit immediately" instead of keeping the
/// sequence open for further composition.
struct Keymap {
    let entries: [String: String]
    /// Every proper prefix of a key, so a sequence can keep composing even
    /// when an intermediate step (e.g. "dhr" on the way to "dhra") has no entry.
    private let prefixes: Set<String>

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
        var prefixes = Set<String>()
        for key in entries.keys {
            var prefix = key
            prefix.removeLast()
            while !prefix.isEmpty, prefixes.insert(prefix).inserted {
                prefix.removeLast()
            }
        }
        self.prefixes = prefixes
    }

    func lookup(_ key: String) -> String? {
        entries[key]
    }

    /// True when at least one longer key starts with `sequence`.
    func canExtend(_ sequence: String) -> Bool {
        prefixes.contains(sequence)
    }

    /// The text for a key sequence: its own entry if it has one, otherwise the
    /// longest matching entries left to right, with unmapped keys kept as typed.
    func render(_ sequence: String) -> String {
        var result = ""
        var rest = Substring(sequence)
        while !rest.isEmpty {
            var length = rest.count
            while length > 0, entries[String(rest.prefix(length))] == nil {
                length -= 1
            }
            if length == 0 {
                result.append(rest.removeFirst())
            } else {
                result += entries[String(rest.prefix(length))]!.withoutCommitMarker
                rest = rest.dropFirst(length)
            }
        }
        return result
    }
}

extension String {
    var commitsImmediately: Bool { hasSuffix("#") }
    var withoutCommitMarker: String { hasSuffix("#") ? String(dropLast()) : self }
}
