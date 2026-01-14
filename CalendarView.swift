import Cocoa

class CalendarView: NSView {
    
    let monthNames = [
        "JANUARY", "FEBRUARY", "MARCH",
        "APRIL", "MAY", "JUNE",
        "JULY", "AUGUST", "SEPTEMBER",
        "OCTOBER", "NOVEMBER", "DECEMBER"
    ]
    
    let currentMonth: Int
    let currentYear: Int
    let currentDay: Int
    var displayYear: Int
    var selectedDate: Date?
    
    // Colors
    let backgroundColor = NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
    let textColor = NSColor.white
    let mutedTextColor = NSColor(calibratedRed: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
    let accentColor = NSColor(calibratedRed: 0.75, green: 0.22, blue: 0.22, alpha: 1.0)
    
    override init(frame frameRect: NSRect) {
        let calendar = Calendar.current
        let now = Date()
        currentMonth = calendar.component(.month, from: now)
        currentYear = calendar.component(.year, from: now)
        currentDay = calendar.component(.day, from: now)
        displayYear = currentYear
        
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        let calendar = Calendar.current
        let now = Date()
        currentMonth = calendar.component(.month, from: now)
        currentYear = calendar.component(.year, from: now)
        currentDay = calendar.component(.day, from: now)
        displayYear = currentYear
        
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
        
        // Left arrow for previous year
        let leftArrow = "‹"
        let leftArrowSize = leftArrow.size(withAttributes: navAttributes)
        let leftArrowRect = NSRect(x: padding, y: y + (topBarHeight - leftArrowSize.height) / 2, width: leftArrowSize.width, height: leftArrowSize.height)
        leftArrow.draw(in: leftArrowRect, withAttributes: navAttributes)
        
        // Today text
        let todayText = "Today"
        let todaySize = todayText.size(withAttributes: navAttributes)
        let todayRect = NSRect(x: padding + 14, y: y + (topBarHeight - todaySize.height) / 2, width: todaySize.width, height: todaySize.height)
        todayText.draw(in: todayRect, withAttributes: navAttributes)
        
        // Right arrow for next year
        let rightArrow = "›"
        let rightArrowSize = rightArrow.size(withAttributes: navAttributes)
        let rightArrowRect = NSRect(x: padding + 18 + todaySize.width, y: y + (topBarHeight - rightArrowSize.height) / 2, width: rightArrowSize.width, height: rightArrowSize.height)
        rightArrow.draw(in: rightArrowRect, withAttributes: navAttributes)
        
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
            
            let leftArrowEnd = padding + 12
            let todayStart = padding + 14
            let todayEnd = todayStart + todaySize.width
            let rightArrowStart = padding + 18 + todaySize.width
            let rightArrowEnd = rightArrowStart + 15
            
            // Left arrow - Previous year
            if point.x >= padding && point.x < leftArrowEnd {
                changeYear(by: -1)
                return
            }
            
            // Today button - Go to current year
            if point.x >= todayStart && point.x < todayEnd {
                goToToday()
                return
            }
            
            // Right arrow - Next year
            if point.x >= rightArrowStart && point.x < rightArrowEnd {
                changeYear(by: 1)
                return
            }
        }
    }
}
