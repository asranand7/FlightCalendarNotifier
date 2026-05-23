import AppKit
import Foundation

// Disable buffering on stdout to capture log output in real-time
setbuf(stdout, nil)

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
