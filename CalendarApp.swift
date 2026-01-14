import Cocoa

@main
class CalendarApp: NSObject, NSApplicationDelegate {
    var appDelegate: AppDelegate!
    
    static func main() {
        let app = NSApplication.shared
        let delegate = CalendarApp()
        app.delegate = delegate
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        appDelegate = AppDelegate()
        appDelegate.applicationDidFinishLaunching()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up if needed
    }
}
