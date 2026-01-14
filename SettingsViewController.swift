import Cocoa
import EventKit

class SettingsViewController: NSViewController {
    
    private var calendarCheckboxes: [(checkbox: NSButton, calendarId: String)] = []
    private var maxEventsSlider: NSSlider!
    private var maxEventsLabel: NSTextField!
    private var allDayCheckbox: NSButton!
    private var launchAtLoginCheckbox: NSButton!
    
    var onSettingsChanged: (() -> Void)?
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.18, alpha: 1.0).cgColor
        
        var yOffset: CGFloat = view.bounds.height - 30
        let padding: CGFloat = 20
        
        // Title
        let titleLabel = createLabel(text: "Settings", fontSize: 16, bold: true)
        titleLabel.frame = NSRect(x: padding, y: yOffset, width: view.bounds.width - padding * 2, height: 20)
        view.addSubview(titleLabel)
        yOffset -= 35
        
        // Calendars Section
        let calendarsLabel = createLabel(text: "Calendars", fontSize: 13, bold: true)
        calendarsLabel.frame = NSRect(x: padding, y: yOffset, width: 200, height: 18)
        view.addSubview(calendarsLabel)
        yOffset -= 5
        
        let calendars = EventManager.shared.getAllCalendars()
        let enabledIDs = SettingsManager.shared.enabledCalendarIDs
        
        for calendar in calendars {
            yOffset -= 22
            let checkbox = NSButton(checkboxWithTitle: calendar.title, target: self, action: #selector(calendarToggled(_:)))
            checkbox.frame = NSRect(x: padding + 10, y: yOffset, width: view.bounds.width - padding * 2 - 10, height: 18)
            
            // If no calendars selected yet, default to all enabled
            if enabledIDs.isEmpty {
                checkbox.state = .on
            } else {
                checkbox.state = enabledIDs.contains(calendar.calendarIdentifier) ? .on : .off
            }
            
            // Color indicator
            let colorView = NSView(frame: NSRect(x: padding + 5, y: yOffset + 4, width: 10, height: 10))
            colorView.wantsLayer = true
            colorView.layer?.backgroundColor = calendar.color.cgColor
            colorView.layer?.cornerRadius = 5
            view.addSubview(colorView)
            
            checkbox.frame.origin.x = padding + 20
            
            // Style checkbox text
            let style = NSMutableParagraphStyle()
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(ofSize: 12)
            ]
            checkbox.attributedTitle = NSAttributedString(string: calendar.title, attributes: attributes)
            
            view.addSubview(checkbox)
            calendarCheckboxes.append((checkbox: checkbox, calendarId: calendar.calendarIdentifier))
        }
        
        yOffset -= 25
        
        // Divider
        let divider1 = NSBox(frame: NSRect(x: padding, y: yOffset, width: view.bounds.width - padding * 2, height: 1))
        divider1.boxType = .separator
        view.addSubview(divider1)
        yOffset -= 20
        
        // Event Display Section
        let displayLabel = createLabel(text: "Event Display", fontSize: 13, bold: true)
        displayLabel.frame = NSRect(x: padding, y: yOffset, width: 200, height: 18)
        view.addSubview(displayLabel)
        yOffset -= 28
        
        // Max Events
        let maxLabel = createLabel(text: "Max events to show:", fontSize: 12, bold: false)
        maxLabel.frame = NSRect(x: padding, y: yOffset, width: 130, height: 18)
        view.addSubview(maxLabel)
        
        maxEventsSlider = NSSlider(value: Double(SettingsManager.shared.maxEventsToShow), minValue: 1, maxValue: 15, target: self, action: #selector(maxEventsChanged(_:)))
        maxEventsSlider.frame = NSRect(x: padding + 135, y: yOffset, width: 100, height: 18)
        view.addSubview(maxEventsSlider)
        
        maxEventsLabel = createLabel(text: "\(SettingsManager.shared.maxEventsToShow)", fontSize: 12, bold: false)
        maxEventsLabel.frame = NSRect(x: padding + 245, y: yOffset, width: 30, height: 18)
        view.addSubview(maxEventsLabel)
        yOffset -= 28
        
        // All-day events
        allDayCheckbox = NSButton(checkboxWithTitle: "Show all-day events", target: self, action: #selector(allDayToggled(_:)))
        allDayCheckbox.frame = NSRect(x: padding, y: yOffset, width: 200, height: 18)
        allDayCheckbox.state = SettingsManager.shared.showAllDayEvents ? .on : .off
        let allDayAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 12)]
        allDayCheckbox.attributedTitle = NSAttributedString(string: "Show all-day events", attributes: allDayAttrs)
        view.addSubview(allDayCheckbox)
        yOffset -= 25
        
        // Divider
        let divider2 = NSBox(frame: NSRect(x: padding, y: yOffset, width: view.bounds.width - padding * 2, height: 1))
        divider2.boxType = .separator
        view.addSubview(divider2)
        yOffset -= 20
        
        // General Section
        let generalLabel = createLabel(text: "General", fontSize: 13, bold: true)
        generalLabel.frame = NSRect(x: padding, y: yOffset, width: 200, height: 18)
        view.addSubview(generalLabel)
        yOffset -= 28
        
        // Launch at Login
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(launchAtLoginToggled(_:)))
        launchAtLoginCheckbox.frame = NSRect(x: padding, y: yOffset, width: 200, height: 18)
        launchAtLoginCheckbox.state = SettingsManager.shared.launchAtLogin ? .on : .off
        let loginAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 12)]
        launchAtLoginCheckbox.attributedTitle = NSAttributedString(string: "Launch at login", attributes: loginAttrs)
        view.addSubview(launchAtLoginCheckbox)
    }
    
    private func createLabel(text: String, fontSize: CGFloat, bold: Bool) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        label.textColor = .white
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        return label
    }
    
    // MARK: - Actions
    
    @objc private func calendarToggled(_ sender: NSButton) {
        var enabledIDs = Set<String>()
        for (checkbox, calendarId) in calendarCheckboxes {
            if checkbox.state == .on {
                enabledIDs.insert(calendarId)
            }
        }
        SettingsManager.shared.enabledCalendarIDs = enabledIDs
        onSettingsChanged?()
    }
    
    @objc private func maxEventsChanged(_ sender: NSSlider) {
        let value = Int(sender.doubleValue)
        SettingsManager.shared.maxEventsToShow = value
        maxEventsLabel.stringValue = "\(value)"
        onSettingsChanged?()
    }
    
    @objc private func allDayToggled(_ sender: NSButton) {
        SettingsManager.shared.showAllDayEvents = sender.state == .on
        onSettingsChanged?()
    }
    
    @objc private func launchAtLoginToggled(_ sender: NSButton) {
        SettingsManager.shared.launchAtLogin = sender.state == .on
    }
}
