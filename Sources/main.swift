import Carbon
import Cocoa
import InputMethodKit

// `SiType --register` adds the bundle to Text Input Sources so it can be
// enabled in System Settings. Used by install.sh and the Homebrew cask.
if CommandLine.arguments.contains("--register") {
    let status = TISRegisterInputSource(Bundle.main.bundleURL as CFURL)
    if status == noErr {
        print("Registered \(Bundle.main.bundlePath)")
        exit(0)
    }
    FileHandle.standardError.write("TISRegisterInputSource failed: \(status)\n".data(using: .utf8)!)
    exit(1)
}

let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String ?? "SiType_Connection"

guard let server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier) else {
    NSLog("SiType: failed to create IMKServer")
    exit(1)
}

// Keep the server alive for the lifetime of the process.
withExtendedLifetime(server) {
    NSApplication.shared.run()
}
