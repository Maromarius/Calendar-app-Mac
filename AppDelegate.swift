import Cocoa

class AppDelegate: NSObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: Any?
    var contextMenu: NSMenu!
    
    func applicationDidFinishLaunching() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use SF Symbol for calendar icon
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            let image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar")
            button.image = image?.withSymbolConfiguration(config)
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
        popover.contentViewController = CalendarViewController()
        popover.behavior = .transient
        
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
}
