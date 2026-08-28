import AppKit

let app = NSApplication.shared
let runtime = AppRuntime()

app.setActivationPolicy(.accessory)
app.delegate = runtime
app.run()
