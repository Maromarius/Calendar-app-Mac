import EventKit

class EventManager {
    static let shared = EventManager()
    
    private let eventStore = EKEventStore()
    private(set) var isAuthorized = false
    
    private init() {
        updateAuthorizationStatus()
    }
    
    private func updateAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            isAuthorized = status == .fullAccess
        } else {
            isAuthorized = status == .authorized
        }
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.updateAuthorizationStatus()
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.updateAuthorizationStatus()
                    completion(granted)
                }
            }
        }
    }
    
    func fetchEvents(for date: Date) -> [EKEvent] {
        guard isAuthorized else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        // Get enabled calendar IDs from settings
        let enabledCalendarIDs = SettingsManager.shared.enabledCalendarIDs
        
        // Get calendars - filter by enabled if any are selected
        var calendars = eventStore.calendars(for: .event)
        if !enabledCalendarIDs.isEmpty {
            calendars = calendars.filter { enabledCalendarIDs.contains($0.calendarIdentifier) }
        }
        
        guard !calendars.isEmpty else { return [] }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: calendars
        )
        
        var events = eventStore.events(matching: predicate)
        
        // Filter all-day events if setting is off
        if !SettingsManager.shared.showAllDayEvents {
            events = events.filter { !$0.isAllDay }
        }
        
        // Sort by start date
        events.sort { $0.startDate < $1.startDate }
        
        return events
    }
    
    func getAllCalendars() -> [EKCalendar] {
        guard isAuthorized else { return [] }
        return eventStore.calendars(for: .event)
    }
}
