import Cocoa
import InputMethodKit

/// Mode IDs declared in Info.plist (ComponentInputModeDict).
enum InputMode: String {
    case phonetic = "com.sitype.inputmethod.SiType.Phonetic"
    case wijesekara = "com.sitype.inputmethod.SiType.Wijesekara"
}

@objc(SiTypeInputController)
final class SiTypeInputController: IMKInputController {

    /// State of the "?" English-passthrough feature (both layouts).
    /// "?" starts English only at the start of a word, so a "?" at the end of a word stays a question mark.
    private enum EnglishState {
        case off
        /// "?" was typed at the start of a word and is shown as marked text; the next key decides.
        case armed
        /// Keys pass through untouched until whitespace is typed.
        case active
    }

    private static let englishTrigger = "?"
    private static let notFound = NSRange(location: NSNotFound, length: NSNotFound)
    /// The original prefixes marked text with a zero-width space so that an
    /// empty composition (e.g. the "z" prefix key) still shows as marked text.
    private static let markedPrefix = "\u{200B}"

    private var buffer = ""
    private var mode: InputMode = .phonetic
    private var englishState: EnglishState = .off
    /// True when the previous key ended a word (whitespace, Return, Tab) or nothing has been typed yet.
    private var atWordStart = true

    private var keymap: Keymap {
        mode == .phonetic ? .phonetic : .wijesekara
    }

    // MARK: - Mode

    override func setValue(_ value: Any!, forTag tag: Int, client sender: Any!) {
        if let id = value as? String, let newMode = InputMode(rawValue: id) {
            if newMode != mode, let client = sender as? IMKTextInput {
                commit(to: client)
            }
            mode = newMode
        }
        super.setValue(value, forTag: tag, client: sender)
    }

    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        atWordStart = true
    }

    override func deactivateServer(_ sender: Any!) {
        if let client = sender as? IMKTextInput {
            commit(to: client)
        }
        super.deactivateServer(sender)
    }

    // MARK: - Text input

    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        guard let string, let client = sender as? IMKTextInput else { return false }

        let wasWordStart = atWordStart
        atWordStart = string.allSatisfy(\.isWhitespace)
        if let handled = handleEnglish(string, client: client, atWordStart: wasWordStart) {
            return handled
        }
        return compose(string, client: client)
    }

    /// Normal Sinhala composition for one key.
    private func compose(_ string: String, client: IMKTextInput) -> Bool {
        let entry = keymap.lookup(string)

        if buffer.isEmpty {
            guard let entry else { return false }
            if entry.commitsImmediately {
                client.insertText(entry.withoutCommitMarker, replacementRange: Self.notFound)
            } else {
                buffer = string
                showMarked(entry, client: client)
            }
            return true
        }

        let extended = buffer + string
        if let extendedValue = keymap.lookup(extended) {
            // The longer sequence is still a valid key: keep composing.
            buffer = extended
            showMarked(extendedValue, client: client)
            return true
        }

        // The sequence can't grow further: commit what we have, then start over.
        client.insertText(currentValue, replacementRange: Self.notFound)
        buffer = ""

        guard let entry else { return false }
        if entry.commitsImmediately {
            client.insertText(entry.withoutCommitMarker, replacementRange: Self.notFound)
        } else {
            buffer = string
            showMarked(entry, client: client)
        }
        return true
    }

    /// Handles the "?" English-passthrough feature.
    /// Returns nil when the key should go through normal Sinhala processing.
    private func handleEnglish(_ string: String, client: IMKTextInput, atWordStart: Bool) -> Bool? {
        let isWhitespace = string.allSatisfy(\.isWhitespace)

        switch englishState {
        case .active:
            if isWhitespace { englishState = .off }
            return false

        case .armed:
            englishState = .off
            if isWhitespace {
                // "? " is an ordinary question mark followed by a space.
                typeTriggerKey(client: client)
                return compose(string, client: client)
            }
            if string == Self.englishTrigger {
                // "??" types a literal question mark.
                typeTriggerKey(client: client)
                return true
            }
            // Replace the marked "?" with the first English character.
            englishState = .active
            client.insertText(string, replacementRange: Self.notFound)
            return true

        case .off:
            guard string == Self.englishTrigger, atWordStart else { return nil }
            commit(to: client)
            englishState = .armed
            client.setMarkedText(Self.englishTrigger,
                                 selectionRange: NSRange(location: 1, length: 0),
                                 replacementRange: Self.notFound)
            return true
        }
    }

    override func didCommand(by aSelector: Selector!, client sender: Any!) -> Bool {
        guard let client = sender as? IMKTextInput else { return false }
        if aSelector == #selector(NSResponder.insertNewline(_:))
            || aSelector == #selector(NSResponder.insertTab(_:)) {
            atWordStart = true
        }

        switch englishState {
        case .armed:
            englishState = .off
            if aSelector == #selector(NSResponder.deleteBackward(_:)) {
                client.setMarkedText("", selectionRange: NSRange(location: 0, length: 0),
                                     replacementRange: Self.notFound)
                atWordStart = true
                return true
            }
            typeTriggerKey(client: client)
        case .active:
            if aSelector == #selector(NSResponder.insertNewline(_:))
                || aSelector == #selector(NSResponder.insertTab(_:))
                || aSelector == #selector(NSResponder.cancelOperation(_:)) {
                englishState = .off
            }
            return false
        case .off:
            break
        }

        guard !buffer.isEmpty else { return false }
        if aSelector == #selector(NSResponder.deleteBackward(_:)) {
            deleteBackward(client: client)
            return true
        }
        commit(to: client)
        return false
    }

    override func commitComposition(_ sender: Any!) {
        guard let client = sender as? IMKTextInput else { return }
        commit(to: client)
    }

    // MARK: - Helpers

    /// The Sinhala text for the current buffer, or the raw keys if it has no mapping.
    private var currentValue: String {
        (keymap.lookup(buffer) ?? buffer).withoutCommitMarker
    }

    private func showMarked(_ value: String, client: IMKTextInput) {
        let text = Self.markedPrefix + value.withoutCommitMarker
        let length = (text as NSString).length
        client.setMarkedText(text, selectionRange: NSRange(location: length, length: 0),
                             replacementRange: Self.notFound)
    }

    private func deleteBackward(client: IMKTextInput) {
        buffer.removeLast()
        if buffer.isEmpty {
            client.setMarkedText("", selectionRange: NSRange(location: 0, length: 0),
                                 replacementRange: Self.notFound)
        } else {
            showMarked(currentValue, client: client)
        }
    }

    /// Types the trigger key as an ordinary "?" (via the keymap, in case a layout ever maps it).
    private func typeTriggerKey(client: IMKTextInput) {
        englishState = .off
        if !compose(Self.englishTrigger, client: client) {
            client.insertText(Self.englishTrigger, replacementRange: Self.notFound)
        }
    }

    private func commit(to client: IMKTextInput) {
        if englishState == .armed {
            typeTriggerKey(client: client)
        }
        englishState = .off
        if !buffer.isEmpty {
            client.insertText(currentValue, replacementRange: Self.notFound)
            buffer = ""
        }
    }
}
