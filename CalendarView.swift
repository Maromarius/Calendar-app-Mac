import Cocoa

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
    var selectedDate: Date?
    
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
        let columns: CGFloat = 3
        let rows: CGFloat = 4
        let horizontalSpacing: CGFloat = 8
        let verticalSpacing: CGFloat = 4
        
        // Calculate grid dimensions
        let availableWidth = bounds.width - (padding * 2) - (horizontalSpacing * (columns - 1))
        let availableHeight = bounds.height - topBarHeight - (padding * 2) - (verticalSpacing * (rows - 1))
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
                
                if cellIndex < weekdayOfFirst {
                    // Previous month's days
                    dayNumber = daysInPrevMonth - weekdayOfFirst + cellIndex + 1
                    isMuted = true
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
        }
    }
}
