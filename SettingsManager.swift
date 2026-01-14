import Foundation
import ServiceManagement

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private let enabledCalendarIDsKey = "enabledCalendarIDs"
    private let maxEventsKey = "maxEventsToShow"
    private let showAllDayEventsKey = "showAllDayEvents"
    private let launchAtLoginKey = "launchAtLogin"
    
    private init() {}
    
    // MARK: - Calendar Selection
    
    var enabledCalendarIDs: Set<String> {
        get {
            let array = defaults.stringArray(forKey: enabledCalendarIDsKey) ?? []
            return Set(array)
        }
        set {
            defaults.set(Array(newValue), forKey: enabledCalendarIDsKey)
        }
    }
    
    // MARK: - Event Display
    
    var maxEventsToShow: Int {
        get {
            let value = defaults.integer(forKey: maxEventsKey)
            return value > 0 ? value : 5 // Default to 5
        }
        set {
            defaults.set(newValue, forKey: maxEventsKey)
        }
    }
    
    var showAllDayEvents: Bool {
        get {
            // Default to true if not set
            if defaults.object(forKey: showAllDayEventsKey) == nil {
                return true
            }
            return defaults.bool(forKey: showAllDayEventsKey)
        }
        set {
            defaults.set(newValue, forKey: showAllDayEventsKey)
        }
    }
    
    // MARK: - Launch at Login
    
    var launchAtLogin: Bool {
        get {
            return defaults.bool(forKey: launchAtLoginKey)
        }
        set {
            defaults.set(newValue, forKey: launchAtLoginKey)
            updateLaunchAtLogin(enabled: newValue)
        }
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}
