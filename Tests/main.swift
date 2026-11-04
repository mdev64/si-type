// Drives SiTypeInputController with a mock client. Run via ./Tests/run.sh.
import Cocoa
import InputMethodKit

final class MockClient: NSObject, IMKTextInput {
    var committed = ""
    var marked = ""

    func insertText(_ string: Any!, replacementRange: NSRange) {
        committed += string as! String
        marked = ""
    }
    func setMarkedText(_ string: Any!, selectionRange: NSRange, replacementRange: NSRange) {
        marked = (string as! String).replacingOccurrences(of: "\u{200B}", with: "")
    }
    func selectedRange() -> NSRange { NSRange(location: 0, length: 0) }
    func markedRange() -> NSRange { NSRange(location: NSNotFound, length: 0) }
    func attributedSubstring(from range: NSRange) -> NSAttributedString! { nil }
    func length() -> Int { 0 }
    func characterIndex(for point: NSPoint, tracking mappingMode: IMKLocationToOffsetMappingMode, inMarkedRange: UnsafeMutablePointer<ObjCBool>!) -> Int { 0 }
    func attributes(forCharacterIndex index: Int, lineHeightRectangle: UnsafeMutablePointer<NSRect>!) -> [AnyHashable: Any]! { [:] }
    func validAttributesForMarkedText() -> [Any]! { [] }
    func overrideKeyboard(withKeyboardNamed keyboardUniqueName: String!) {}
    func selectMode(_ modeIdentifier: String!) {}
    func supportsUnicode() -> Bool { true }
    func bundleIdentifier() -> String! { "test" }
    func windowLevel() -> CGWindowLevel { 0 }
    func supportsProperty(_ property: TSMDocumentPropertyTag) -> Bool { false }
    func uniqueClientIdentifierString() -> String! { "test" }
    func string(from range: NSRange, actualRange: NSRangePointer!) -> String! { "" }
    func firstRect(forCharacterRange aRange: NSRange, actualRange: NSRangePointer!) -> NSRect { .zero }
}

var failures = 0

/// "\b" = backspace, "\n" = return, "\u{1}" = commit (focus loss).
func type(_ keys: String, mode: InputMode = .phonetic) -> String {
    let client = MockClient()
    let controller = SiTypeInputController(server: nil, delegate: nil, client: nil)!
    controller.setValue(mode.rawValue, forTag: 0, client: client)
    for ch in keys {
        let key = String(ch)
        switch key {
        case "\u{8}":
            if !controller.didCommand(by: #selector(NSResponder.deleteBackward(_:)), client: client) {
                if !client.committed.isEmpty { client.committed.removeLast() }
            }
        case "\n":
            if !controller.didCommand(by: #selector(NSResponder.insertNewline(_:)), client: client) {
                client.committed += "\n"
            }
        default:
            if !controller.inputText(key, client: client) { client.committed += key }
        }
    }
    controller.commitComposition(client)
    return client.committed
}

func check(_ keys: String, _ expected: String, mode: InputMode = .phonetic) {
    let got = type(keys, mode: mode)
    let ok = got == expected
    if !ok { failures += 1 }
    print("\(ok ? "PASS" : "FAIL")  \(keys.debugDescription) → \(got.debugDescription)\(ok ? "" : "  expected \(expected.debugDescription)")")
}

// Phonetic transliteration
check("ammaa", "අම්මා")
check("shrii", "ශ්‍රී")
check("mama gedhara yanawaa", "මම ගෙදර යනවා")
check("kohomadha?", "කොහොමද?")
// Backspace removes one keystroke from the composition: "maa" → "ma" → "m".
check("ammaa\u{8}\u{8}", "අම්ම්")
// "?" English passthrough (start of a word only)
check("mama ?hello yanawaa", "මම hello යනවා")
check("?Hello, kohomadha?", "Hello, කොහොමද?")
check("?user@mail.com ?https://x.lk/a?b=1 hari", "user@mail.com https://x.lk/a?b=1 හරි")
check("mama ? yanawaa", "මම ? යනවා")
check("??", "?")
check("kohomadha?", "කොහොමද?")
check("a?b", "අ?බ්")
check("?\u{8}a", "අ")
check("?abc\u{8}d ammaa", "abd අම්මා")
check("?email\nammaa", "email\nඅම්මා")
check("hari\n?ok ammaa", "හරි\nok අම්මා")
check("mama: yanawaa;", "මම: යනවා;")
// Wijesekara: "?" works the same; ";" and ":" keep their letters
check("uu ?hello ,shkjd", "මම hello ලියනවා", mode: .wijesekara)
check("uu ,shkjd?", "මම ලියනවා?", mode: .wijesekara)
check(";", "ත", mode: .wijesekara)
check(":", "ථ", mode: .wijesekara)
check("f:a", "ථේ", mode: .wijesekara)
check("?\u{8}wd", "ආ", mode: .wijesekara)
check("wd", "ආ", mode: .wijesekara)

print(failures == 0 ? "\nAll passed" : "\n\(failures) failed")
exit(failures == 0 ? 0 : 1)
