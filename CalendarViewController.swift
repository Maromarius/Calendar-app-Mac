import Cocoa

class CalendarViewController: NSViewController {
    
    var calendarView: CalendarView!
    
    override func loadView() {
        calendarView = CalendarView()
        self.view = calendarView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update size when date changes
        calendarView.onDateChanged = { [weak self] in
            self?.updatePreferredSize()
        }
        
        updatePreferredSize()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updatePreferredSize()
    }
    
    func updatePreferredSize() {
        let height = calendarView.getRequiredHeight()
        preferredContentSize = NSSize(width: 420, height: height)
    }
}
