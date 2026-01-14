import Cocoa
import EventKit

class CalendarView: NSView {
    
    let monthNames = [
        "JANUARY", "FEBRUARY", "MARCH",
        "APRIL", "MAY", "JUNE",
        "JULY", "AUGUST", "SEPTEMBER",
        "OCTOBER", "NOVEMBER", "DECEMBER"
    ]
    
    var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }
    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    var currentDay: Int {
        Calendar.current.component(.day, from: Date())
    }
    var displayYear: Int
    var selectedDate: Date = Date() // Default to today
    
    // Callbacks
    var onSettingsClicked: (() -> Void)?
    var onDateChanged: (() -> Void)?
    
    // Hover tracking
    var isHoveringLeftArrow = false
    var isHoveringRightArrow = false
    var trackingArea: NSTrackingArea?
    
    // Colors
    let backgroundColor = NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
    let textColor = NSColor.white
    let mutedTextColor = NSColor(calibratedRed: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
    let accentColor = NSColor(calibratedRed: 0.75, green: 0.22, blue: 0.22, alpha: 1.0)
    
    override init(frame frameRect: NSRect) {
        displayYear = Calendar.current.component(.year, from: Date())
        
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        displayYear = Calendar.current.component(.year, from: Date())
        
        super.init(coder: coder)
        setupView()
    }
    
    func goToToday() {
        displayYear = currentYear
        selectedDate = Date()
        onDateChanged?()
        needsDisplay = true
    }
    
    func changeYear(by offset: Int) {
        displayYear += offset
        needsDisplay = true
    }
    
    func setupView() {
        wantsLayer = true
        layer?.backgroundColor = backgroundColor.cgColor
        // updateTrackingAreas() - Removed manual call
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let existing = trackingArea {
            removeTrackingArea(existing)
            trackingArea = nil
        }
        
        // Guard against empty bounds (which can happen during init)
        if bounds.isEmpty || bounds.width < 1 || bounds.height < 1 {
            return
        }
        
        let newTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .assumeInside],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(newTrackingArea)
        trackingArea = newTrackingArea
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        updateHoverState(at: location)
    }
    
    override func mouseExited(with event: NSEvent) {
        isHoveringLeftArrow = false
        isHoveringRightArrow = false
        needsDisplay = true
    }
    
    func updateHoverState(at point: CGPoint) {
        let padding: CGFloat = 12
        let topBarHeight: CGFloat = 32
        let topBarY = bounds.height - topBarHeight
        
        let oldLeftHover = isHoveringLeftArrow
        let oldRightHover = isHoveringRightArrow
        
        isHoveringLeftArrow = false
        isHoveringRightArrow = false
        
        if point.y > topBarY {
            let leftArrowHitZone = NSRect(x: padding - 4, y: topBarY, width: 24, height: topBarHeight)
            let rightArrowHitZone = NSRect(x: padding + 32 + 30, y: topBarY, width: 24, height: topBarHeight)
            
            if leftArrowHitZone.contains(point) {
                isHoveringLeftArrow = true
            } else if rightArrowHitZone.contains(point) {
                isHoveringRightArrow = true
            }
        }
        
        if oldLeftHover != isHoveringLeftArrow || oldRightHover != isHoveringRightArrow {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Fill background
        backgroundColor.setFill()
        NSBezierPath.fill(bounds)
        
        let padding: CGFloat = 12
        let topBarHeight: CGFloat = 32
        let fixedCalendarHeight: CGFloat = 540 // Fixed height for calendar grid
        let eventsHeight = calculateEventsHeight()
        let columns: CGFloat = 3
        let rows: CGFloat = 4
        let horizontalSpacing: CGFloat = 8
        let verticalSpacing: CGFloat = 4
        
        // Calculate grid dimensions using fixed calendar height
        let availableWidth = bounds.width - (padding * 2) - (horizontalSpacing * (columns - 1))
        let availableHeight = fixedCalendarHeight - (padding * 2) - (verticalSpacing * (rows - 1))
        let cellWidth = availableWidth / columns
        let cellHeight = availableHeight / rows
        
        // Draw top bar
        drawTopBar(topBarHeight: topBarHeight, padding: padding)
        
        // Draw months in 4 rows x 3 columns
        for (index, monthName) in monthNames.enumerated() {
            let column = CGFloat(index % 3)
            let row = CGFloat(index / 3)
            
            let x = padding + column * (cellWidth + horizontalSpacing)
            let y = bounds.height - topBarHeight - padding - (row + 1) * cellHeight - row * verticalSpacing
            
            let monthRect = NSRect(x: x, y: y, width: cellWidth, height: cellHeight)
            drawMonth(rect: monthRect, monthName: monthName, monthNumber: index + 1)
        }
        
        // Draw events section at the bottom
        drawEventsSection(rect: NSRect(x: padding, y: padding, width: bounds.width - padding * 2, height: eventsHeight - padding))
    }
    
    func calculateEventsHeight() -> CGFloat {
        let events = EventManager.shared.fetchEvents(for: selectedDate)
        let headerHeight: CGFloat = 32 // Header + divider + top padding
        let eventRowHeight: CGFloat = 22
        let bottomPadding: CGFloat = 8
        let minHeight: CGFloat = 60 // Minimum even with no events
        let maxHeight: CGFloat = 400 // Maximum to prevent overflow
        
        let calculatedHeight = headerHeight + CGFloat(events.count) * eventRowHeight + bottomPadding
        return min(max(calculatedHeight, minHeight), maxHeight)
    }
    
    func getRequiredHeight() -> CGFloat {
        let topBarHeight: CGFloat = 32
        let fixedCalendarHeight: CGFloat = 540
        let eventsHeight = calculateEventsHeight()
        let padding: CGFloat = 12
        return topBarHeight + fixedCalendarHeight + eventsHeight + padding
    }
    
    func drawEventsSection(rect: NSRect) {
        // Section header - show date or "TODAY'S EVENTS"
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(selectedDate)
        
        let headerText: String
        if isToday {
            headerText = "TODAY'S EVENTS"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            headerText = formatter.string(from: selectedDate).uppercased()
        }
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: textColor
        ]
        let headerRect = NSRect(x: rect.origin.x, y: rect.origin.y + rect.height - 18, width: rect.width, height: 18)
        headerText.draw(in: headerRect, withAttributes: headerAttributes)
        
        // Divider line
        let dividerY = rect.origin.y + rect.height - 24
        NSColor.gray.withAlphaComponent(0.3).setStroke()
        let dividerPath = NSBezierPath()
        dividerPath.move(to: NSPoint(x: rect.origin.x, y: dividerY))
        dividerPath.line(to: NSPoint(x: rect.origin.x + rect.width, y: dividerY))
        dividerPath.lineWidth = 0.5
        dividerPath.stroke()
        
        // Get events for selected date
        let events = EventManager.shared.fetchEvents(for: selectedDate)
        
        if events.isEmpty {
            let emptyAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: mutedTextColor
            ]
            let emptyText = isToday ? "No events today" : "No events"
            let emptyRect = NSRect(x: rect.origin.x, y: rect.origin.y + rect.height / 2 - 20, width: rect.width, height: 16)
            emptyText.draw(in: emptyRect, withAttributes: emptyAttributes)
            return
        }
        
        // Draw events
        let eventHeight: CGFloat = 22
        var yOffset = dividerY - 6 - eventHeight
        
        for event in events {
            if yOffset < rect.origin.y - 5 { break } // Allow slight overflow
            
            // Calendar color dot
            let dotSize: CGFloat = 8
            let dotRect = NSRect(x: rect.origin.x, y: yOffset + (eventHeight - dotSize) / 2, width: dotSize, height: dotSize)
            let dotPath = NSBezierPath(ovalIn: dotRect)
            (event.calendar.color ?? NSColor.blue).setFill()
            dotPath.fill()
            
            // Time
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = event.isAllDay ? "All day" : "h:mm a"
            let timeString = event.isAllDay ? "All day" : timeFormatter.string(from: event.startDate)
            
            let timeAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: mutedTextColor
            ]
            let timeRect = NSRect(x: rect.origin.x + 14, y: yOffset + 4, width: 60, height: 16)
            timeString.draw(in: timeRect, withAttributes: timeAttributes)
            
            // Event title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: textColor
            ]
            let titleRect = NSRect(x: rect.origin.x + 75, y: yOffset + 4, width: rect.width - 80, height: 16)
            (event.title ?? "(No title)").draw(in: titleRect, withAttributes: titleAttributes)
            
            // Move to next row
            yOffset -= eventHeight
        }
    }
    
    func drawTopBar(topBarHeight: CGFloat, padding: CGFloat) {
        let y = bounds.height - topBarHeight
        
        // Navigation arrows and Today button
        let navAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: textColor
        ]
        
        // Arrow attributes (larger, with hover effect)
        let leftArrowColor = isHoveringLeftArrow ? textColor.withAlphaComponent(0.6) : textColor
        let rightArrowColor = isHoveringRightArrow ? textColor.withAlphaComponent(0.6) : textColor
        
        let leftArrowAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: leftArrowColor
        ]
        let rightArrowAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: rightArrowColor
        ]
        
        // Left arrow for previous year
        let leftArrow = "‹"
        let leftArrowSize = leftArrow.size(withAttributes: leftArrowAttributes)
        let leftArrowRect = NSRect(x: padding + 2, y: y + (topBarHeight - leftArrowSize.height) / 2 - 1, width: leftArrowSize.width, height: leftArrowSize.height)
        leftArrow.draw(in: leftArrowRect, withAttributes: leftArrowAttributes)
        
        // Today text
        let todayText = "Today"
        let todaySize = todayText.size(withAttributes: navAttributes)
        let todayRect = NSRect(x: padding + 18, y: y + (topBarHeight - todaySize.height) / 2, width: todaySize.width, height: todaySize.height)
        todayText.draw(in: todayRect, withAttributes: navAttributes)
        
        // Right arrow for next year
        let rightArrow = "›"
        let rightArrowSize = rightArrow.size(withAttributes: rightArrowAttributes)
        let rightArrowRect = NSRect(x: padding + 22 + todaySize.width, y: y + (topBarHeight - rightArrowSize.height) / 2 - 1, width: rightArrowSize.width, height: rightArrowSize.height)
        rightArrow.draw(in: rightArrowRect, withAttributes: rightArrowAttributes)
        
        // Center: Year
        let yearAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: textColor
        ]
        let yearString = "\(displayYear)"
        let yearSize = yearString.size(withAttributes: yearAttributes)
        let yearRect = NSRect(
            x: (bounds.width - yearSize.width) / 2,
            y: y + (topBarHeight - yearSize.height) / 2,
            width: yearSize.width,
            height: yearSize.height
        )
        yearString.draw(in: yearRect, withAttributes: yearAttributes)
        
        // Right: Settings icon (gear)
        let gearAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: textColor
        ]
        let gearIcon = "⚙"
        let gearSize = gearIcon.size(withAttributes: gearAttributes)
        let gearRect = NSRect(
            x: bounds.width - padding - gearSize.width,
            y: y + (topBarHeight - gearSize.height) / 2,
            width: gearSize.width,
            height: gearSize.height
        )
        gearIcon.draw(in: gearRect, withAttributes: gearAttributes)
    }
    
    func drawMonth(rect: NSRect, monthName: String, monthNumber: Int) {
        let isCurrentMonth = (monthNumber == currentMonth && displayYear == currentYear)
        let monthLabelHeight: CGFloat = 18
        let calendarAreaTop = rect.origin.y
        let calendarAreaHeight = rect.height - monthLabelHeight
        
        // Draw month name (left-aligned, uppercase, bold)
        let monthColor = isCurrentMonth ? accentColor : textColor
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: monthColor
        ]
        
        let monthSize = monthName.size(withAttributes: monthAttributes)
        let monthLabelRect = NSRect(
            x: rect.origin.x,
            y: rect.origin.y + rect.height - monthLabelHeight,
            width: monthSize.width,
            height: monthSize.height
        )
        monthName.draw(in: monthLabelRect, withAttributes: monthAttributes)
        
        // Draw calendar grid (no weekday headers like reference)
        drawCalendarGrid(
            rect: NSRect(x: rect.origin.x, y: calendarAreaTop, width: rect.width, height: calendarAreaHeight),
            monthNumber: monthNumber,
            isCurrentMonth: isCurrentMonth
        )
    }
    
    func drawCalendarGrid(rect: NSRect, monthNumber: Int, isCurrentMonth: Bool) {
        let calendar = Calendar.current
        let cellWidth = rect.width / 7
        let cellHeight = rect.height / 6
        
        // Get first day of month and number of days
        var components = DateComponents()
        components.year = displayYear
        components.month = monthNumber
        components.day = 1
        
        guard let firstOfMonth = calendar.date(from: components) else { return }
        
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth) - 1 // 0 = Sunday
        let numberOfDays = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
        
        // Get previous month's days
        var prevMonth = monthNumber - 1
        var prevYear = displayYear
        if prevMonth < 1 {
            prevMonth = 12
            prevYear -= 1
        }
        let prevMonthComponents = DateComponents(year: prevYear, month: prevMonth, day: 1)
        let prevMonthDate = calendar.date(from: prevMonthComponents) ?? firstOfMonth
        let daysInPrevMonth = calendar.range(of: .day, in: .month, for: prevMonthDate)?.count ?? 30
        
        // Draw 6 weeks of days
        var day = 1
        var nextMonthDay = 1
        
        for week in 0..<6 {
            for weekday in 0..<7 {
                let cellIndex = week * 7 + weekday
                let cellX = rect.origin.x + CGFloat(weekday) * cellWidth
                let cellY = rect.origin.y + rect.height - CGFloat(week + 1) * cellHeight
                
                var dayNumber: Int
                var isMuted = false
                var isToday = false
                var isSelected = false
                var actualYear = displayYear
                var actualMonth = monthNumber
                
                if cellIndex < weekdayOfFirst {
                    // Previous month's days
                    dayNumber = daysInPrevMonth - weekdayOfFirst + cellIndex + 1
                    isMuted = true
                    actualMonth = prevMonth
                    actualYear = prevYear
                } else if day <= numberOfDays {
                    // Current month's days
                    dayNumber = day
                    if isCurrentMonth && day == currentDay {
                        isToday = true
                    }
                    day += 1
                } else {
                    // Next month's days
                    dayNumber = nextMonthDay
                    nextMonthDay += 1
                    isMuted = true
                    actualMonth = monthNumber == 12 ? 1 : monthNumber + 1
                    actualYear = monthNumber == 12 ? displayYear + 1 : displayYear
                }
                
                // Check if this day is selected
                let selectedComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                if selectedComponents.year == actualYear && 
                   selectedComponents.month == actualMonth && 
                   selectedComponents.day == dayNumber {
                    isSelected = true
                }
                
                let dayString = "\(dayNumber)"
                let textColorForDay = isMuted ? mutedTextColor : textColor
                
                let dayAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 10, weight: isToday ? .bold : .regular),
                    .foregroundColor: isToday ? NSColor.white : textColorForDay
                ]
                
                let daySize = dayString.size(withAttributes: dayAttributes)
                let dayRect = NSRect(
                    x: cellX + (cellWidth - daySize.width) / 2,
                    y: cellY + (cellHeight - daySize.height) / 2,
                    width: daySize.width,
                    height: daySize.height
                )
                
                // Highlight today with red circle
                if isToday {
                    let circleSize: CGFloat = min(cellWidth, cellHeight) * 0.9
                    let circleRect = NSRect(
                        x: cellX + (cellWidth - circleSize) / 2,
                        y: cellY + (cellHeight - circleSize) / 2,
                        width: circleSize,
                        height: circleSize
                    )
                    let circlePath = NSBezierPath(ovalIn: circleRect)
                    accentColor.setFill()
                    circlePath.fill()
                } else if isSelected {
                    // Highlight selected day with gray ring
                    let circleSize: CGFloat = min(cellWidth, cellHeight) * 0.9
                    let circleRect = NSRect(
                        x: cellX + (cellWidth - circleSize) / 2,
                        y: cellY + (cellHeight - circleSize) / 2,
                        width: circleSize,
                        height: circleSize
                    )
                    let circlePath = NSBezierPath(ovalIn: circleRect)
                    NSColor.gray.withAlphaComponent(0.4).setFill()
                    circlePath.fill()
                }
                
                dayString.draw(in: dayRect, withAttributes: dayAttributes)
            }
        }
    }
    
    // MARK: - Mouse Interaction
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        handleClick(at: location)
    }
    
    func handleClick(at point: CGPoint) {
        let padding: CGFloat = 12
        let topBarHeight: CGFloat = 32
        let topBarY = bounds.height - topBarHeight
        
        // Check if click is in top bar
        if point.y > topBarY {
            let navAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: textColor
            ]
            let todayText = "Today"
            let todaySize = todayText.size(withAttributes: navAttributes)
            
            // Expanded hit zones for better clickability
            let leftArrowHitZone = NSRect(x: padding - 4, y: topBarY, width: 24, height: topBarHeight)
            let todayHitZone = NSRect(x: padding + 16, y: topBarY, width: todaySize.width + 8, height: topBarHeight)
            let rightArrowHitZone = NSRect(x: padding + 22 + todaySize.width, y: topBarY, width: 24, height: topBarHeight)
            
            // Left arrow - Previous year
            if leftArrowHitZone.contains(point) {
                changeYear(by: -1)
                return
            }
            
            // Today button - Go to current year
            if todayHitZone.contains(point) {
                goToToday()
                return
            }
            
            // Right arrow - Next year
            if rightArrowHitZone.contains(point) {
                changeYear(by: 1)
                return
            }
            
            // Gear icon - Settings
            let gearHitZone = NSRect(x: bounds.width - padding - 20, y: topBarY, width: 24, height: topBarHeight)
            if gearHitZone.contains(point) {
                onSettingsClicked?()
                return
            }
        }
        
        // Check if click is in the calendar grid area
        let fixedCalendarHeight: CGFloat = 540
        let columns: CGFloat = 3
        let rows: CGFloat = 4
        let horizontalSpacing: CGFloat = 8
        let verticalSpacing: CGFloat = 4
        
        let availableWidth = bounds.width - (padding * 2) - (horizontalSpacing * (columns - 1))
        let availableHeight = fixedCalendarHeight - (padding * 2) - (verticalSpacing * (rows - 1))
        let monthCellWidth = availableWidth / columns
        let monthCellHeight = availableHeight / rows
        
        // Find which month was clicked
        for monthIndex in 0..<12 {
            let column = CGFloat(monthIndex % 3)
            let row = CGFloat(monthIndex / 3)
            
            let monthX = padding + column * (monthCellWidth + horizontalSpacing)
            let monthY = bounds.height - topBarHeight - padding - (row + 1) * monthCellHeight - row * verticalSpacing
            
            let monthRect = NSRect(x: monthX, y: monthY, width: monthCellWidth, height: monthCellHeight)
            
            if monthRect.contains(point) {
                // Found the month, now find the day
                let monthNumber = monthIndex + 1
                let monthLabelHeight: CGFloat = 18
                let calendarAreaTop = monthRect.origin.y
                let calendarAreaHeight = monthRect.height - monthLabelHeight
                
                let dayCellWidth = monthRect.width / 7
                let dayCellHeight = calendarAreaHeight / 6
                
                // Get first day of month
                let calendar = Calendar.current
                var components = DateComponents()
                components.year = displayYear
                components.month = monthNumber
                components.day = 1
                
                guard let firstOfMonth = calendar.date(from: components) else { return }
                
                let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth) - 1
                let numberOfDays = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
                
                // Get previous month info
                var prevMonth = monthNumber - 1
                var prevYear = displayYear
                if prevMonth < 1 {
                    prevMonth = 12
                    prevYear -= 1
                }
                let prevMonthComponents = DateComponents(year: prevYear, month: prevMonth, day: 1)
                let prevMonthDate = calendar.date(from: prevMonthComponents) ?? firstOfMonth
                let daysInPrevMonth = calendar.range(of: .day, in: .month, for: prevMonthDate)?.count ?? 30
                
                // Find which cell was clicked
                for week in 0..<6 {
                    for weekday in 0..<7 {
                        let cellX = monthRect.origin.x + CGFloat(weekday) * dayCellWidth
                        let cellY = calendarAreaTop + calendarAreaHeight - CGFloat(week + 1) * dayCellHeight
                        
                        let cellRect = NSRect(x: cellX, y: cellY, width: dayCellWidth, height: dayCellHeight)
                        
                        if cellRect.contains(point) {
                            let cellIndex = week * 7 + weekday
                            var day = 1
                            var nextMonthDay = 1
                            
                            var clickedDay = 0
                            var clickedMonth = monthNumber
                            var clickedYear = displayYear
                            
                            // Recalculate which day this cell represents
                            for i in 0..<42 {
                                if i == cellIndex {
                                    if i < weekdayOfFirst {
                                        clickedDay = daysInPrevMonth - weekdayOfFirst + i + 1
                                        clickedMonth = prevMonth
                                        clickedYear = prevYear
                                    } else if day <= numberOfDays {
                                        clickedDay = day
                                    } else {
                                        clickedDay = nextMonthDay
                                        clickedMonth = monthNumber == 12 ? 1 : monthNumber + 1
                                        clickedYear = monthNumber == 12 ? displayYear + 1 : displayYear
                                    }
                                    break
                                }
                                
                                if i < weekdayOfFirst {
                                    // Skip
                                } else if day <= numberOfDays {
                                    day += 1
                                } else {
                                    nextMonthDay += 1
                                }
                            }
                            
                            // Create the date and select it
                            var dateComponents = DateComponents()
                            dateComponents.year = clickedYear
                            dateComponents.month = clickedMonth
                            dateComponents.day = clickedDay
                            
                            if let clickedDate = calendar.date(from: dateComponents) {
                                selectedDate = clickedDate
                                onDateChanged?()
                                needsDisplay = true
                            }
                            return
                        }
                    }
                }
                return
            }
        }
    }
}
