import Cocoa

class AppDelegate: NSObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: Any?
    var contextMenu: NSMenu!
    var midnightTimer: Timer?
    var settingsWindow: NSWindow?
    var calendarView: CalendarView?
    
    func applicationDidFinishLaunching() {
        // Request calendar access
        EventManager.shared.requestAccess { [weak self] granted in
            if granted {
                self?.calendarView?.needsDisplay = true
            }
        }
        
        // Schedule icon update at midnight
        scheduleMidnightUpdate()
        
        // Also update icon when waking from sleep or significant time change
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWakeFromSleep),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSignificantTimeChange),
            name: NSNotification.Name.NSSystemClockDidChange,
            object: nil
        )
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Create calendar icon with today's date
            button.image = createCalendarIcon()
            button.action = #selector(handleClick(_:))
            button.target = self
            
            // Register for both left and right clicks
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create context menu for right-click/Option-click
        contextMenu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit Calendar", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quitItem.target = self
        contextMenu.addItem(quitItem)
        
        // Create popover
        popover = NSPopover()
        let calendarVC = CalendarViewController()
        popover.contentViewController = calendarVC
        popover.behavior = .transient
        
        // Get reference to calendar view and set up settings callback
        if let view = calendarVC.view as? CalendarView {
            calendarView = view
            view.onSettingsClicked = { [weak self] in
                self?.showSettings()
            }
        }
        
        // Monitor clicks outside popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                self?.closePopover(event)
            }
        }
    }
    
    @objc func handleClick(_ sender: Any?) {
        let event = NSApp.currentEvent
        
        // Show menu if it's a right click or if Option key is held
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.option) == true {
            contextMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: statusItem.button?.bounds.height ?? 0), in: statusItem.button)
        } else {
            togglePopover(sender)
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func closePopover(_ sender: Any?) {
        popover.performClose(sender)
    }
    
    @objc func quitApp(_ sender: Any?) {
        NSApplication.shared.terminate(sender)
    }
    
    func showSettings() {
        // Close the popover first
        closePopover(nil)
        
        // If window already exists, bring it to front
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create settings window
        let settingsVC = SettingsViewController()
        settingsVC.onSettingsChanged = { [weak self] in
            self?.calendarView?.needsDisplay = true
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Calendar Settings"
        window.contentViewController = settingsVC
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }
    
    @objc func handleWakeFromSleep(_ notification: Notification) {
        // Check if date changed while sleeping and update icon
        updateIcon()
        scheduleMidnightUpdate() // Reschedule in case we missed midnight
    }
    
    @objc func handleSignificantTimeChange(_ notification: Notification) {
        // Handle timezone changes or manual time adjustments
        updateIcon()
        scheduleMidnightUpdate()
    }
    
    func scheduleMidnightUpdate() {
        // Calculate time until next midnight
        let calendar = Calendar.current
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let nextMidnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            return
        }
        
        let timeInterval = nextMidnight.timeIntervalSince(now)
        
        // Schedule timer
        midnightTimer?.invalidate()
        midnightTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.updateIcon()
            self?.scheduleMidnightUpdate() // Schedule next midnight update
        }
    }
    
    func updateIcon() {
        if let button = statusItem.button {
            button.image = createCalendarIcon()
        }
    }
    
    func createCalendarIcon() -> NSImage {
        let day = Calendar.current.component(.day, from: Date())
        let size = NSSize(width: 22, height: 22)
        
        let image = NSImage(size: size, flipped: true) { rect in
            let padding: CGFloat = 1
            let calendarRect = NSRect(
                x: padding,
                y: padding,
                width: rect.width - padding * 2,
                height: rect.height - padding * 2
            )
            
            // Calendar body - rounded rectangle
            let cornerRadius: CGFloat = 3
            let bodyPath = NSBezierPath(roundedRect: calendarRect, xRadius: cornerRadius, yRadius: cornerRadius)
            NSColor.labelColor.withAlphaComponent(0.9).setStroke()
            bodyPath.lineWidth = 1.2
            bodyPath.stroke()
            
            // Red header bar at top
            let headerHeight: CGFloat = 6
            let headerRect = NSRect(
                x: calendarRect.origin.x,
                y: calendarRect.origin.y,
                width: calendarRect.width,
                height: headerHeight
            )
            let headerPath = NSBezierPath()
            headerPath.move(to: NSPoint(x: headerRect.minX + cornerRadius, y: headerRect.minY))
            headerPath.appendArc(withCenter: NSPoint(x: headerRect.minX + cornerRadius, y: headerRect.minY + cornerRadius),
                                  radius: cornerRadius,
                                  startAngle: 180,
                                  endAngle: 270)
            headerPath.line(to: NSPoint(x: headerRect.maxX - cornerRadius, y: headerRect.minY))
            headerPath.appendArc(withCenter: NSPoint(x: headerRect.maxX - cornerRadius, y: headerRect.minY + cornerRadius),
                                  radius: cornerRadius,
                                  startAngle: 270,
                                  endAngle: 360)
            headerPath.line(to: NSPoint(x: headerRect.maxX, y: headerRect.maxY))
            headerPath.line(to: NSPoint(x: headerRect.minX, y: headerRect.maxY))
            headerPath.close()
            
            NSColor(calibratedRed: 0.85, green: 0.2, blue: 0.2, alpha: 1.0).setFill()
            headerPath.fill()
            
            // Calendar rings/binding holes
            let ringY = calendarRect.origin.y - 1
            let ringWidth: CGFloat = 2
            let ringHeight: CGFloat = 4
            let ringSpacing: CGFloat = 6
            let ringStartX = calendarRect.midX - ringSpacing / 2 - ringWidth / 2
            
            NSColor.labelColor.setStroke()
            for i in 0..<2 {
                let ringX = ringStartX + CGFloat(i) * ringSpacing
                let ringPath = NSBezierPath()
                ringPath.move(to: NSPoint(x: ringX, y: ringY))
                ringPath.line(to: NSPoint(x: ringX, y: ringY + ringHeight))
                ringPath.lineWidth = ringWidth
                ringPath.lineCapStyle = .round
                ringPath.stroke()
            }
            
            // Day number
            let dayString = "\(day)"
            let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ]
            
            let textSize = dayString.size(withAttributes: attributes)
            let textRect = NSRect(
                x: calendarRect.midX - textSize.width / 2,
                y: calendarRect.midY - textSize.height / 2 + 2.5,
                width: textSize.width,
                height: textSize.height
            )
            dayString.draw(in: textRect, withAttributes: attributes)
            
            return true
        }
        
        image.isTemplate = false
        return image
    }
}
