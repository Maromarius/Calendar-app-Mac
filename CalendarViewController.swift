import Cocoa

class CalendarViewController: NSViewController {
    
    override func loadView() {
        let calendarView = CalendarView()
        self.view = calendarView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set preferred content size for the popover - narrower and taller
        preferredContentSize = NSSize(width: 420, height: 580)
    }
}
