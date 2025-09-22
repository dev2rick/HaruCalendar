//
//  HaruCalendarExtensions.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - Date Extensions

public extension Date {
    
    /// Returns the first day of the month for this date
    func startOfMonth(using calendar: Calendar = Calendar.current) -> Date {
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns the last day of the month for this date
    func endOfMonth(using calendar: Calendar = Calendar.current) -> Date {
        let startOfMonth = startOfMonth(using: calendar)
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return self
        }
        return endOfMonth
    }
    
    /// Returns the first day of the week for this date
    func startOfWeek(using calendar: Calendar = Calendar.current) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns the last day of the week for this date
    func endOfWeek(using calendar: Calendar = Calendar.current) -> Date {
        let startOfWeek = startOfWeek(using: calendar)
        guard let endOfWeek = calendar.date(byAdding: DateComponents(day: 6), to: startOfWeek) else {
            return self
        }
        return endOfWeek
    }
    
    /// Checks if this date is in the same day as another date
    func isSameDay(as date: Date, using calendar: Calendar = Calendar.current) -> Bool {
        return calendar.isDate(self, inSameDayAs: date)
    }
    
    /// Checks if this date is in the same month as another date
    func isSameMonth(as date: Date, using calendar: Calendar = Calendar.current) -> Bool {
        let components1 = calendar.dateComponents([.year, .month], from: self)
        let components2 = calendar.dateComponents([.year, .month], from: date)
        return components1.year == components2.year && components1.month == components2.month
    }
    
    /// Checks if this date is in the same week as another date
    func isSameWeek(as date: Date, using calendar: Calendar = Calendar.current) -> Bool {
        let components1 = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        let components2 = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return components1.yearForWeekOfYear == components2.yearForWeekOfYear && 
               components1.weekOfYear == components2.weekOfYear
    }
    
    /// Returns a date by adding the specified number of days
    func adding(days: Int, using calendar: Calendar = Calendar.current) -> Date? {
        return calendar.date(byAdding: .day, value: days, to: self)
    }
    
    /// Returns a date by adding the specified number of months
    func adding(months: Int, using calendar: Calendar = Calendar.current) -> Date? {
        return calendar.date(byAdding: .month, value: months, to: self)
    }
    
    /// Returns a date by adding the specified number of weeks
    func adding(weeks: Int, using calendar: Calendar = Calendar.current) -> Date? {
        return calendar.date(byAdding: .weekOfYear, value: weeks, to: self)
    }
}

// MARK: - Calendar Extensions

public extension Calendar {
    
    /// Returns the number of days in the specified month
    func numberOfDaysInMonth(for date: Date) -> Int {
        guard let range = range(of: .day, in: .month, for: date) else { return 0 }
        return range.count
    }
    
    /// Returns the weekday index for the first day of the month (1-7, where 1 is Sunday)
    func weekdayOfFirstDayInMonth(for date: Date) -> Int {
        let startOfMonth = date.startOfMonth(using: self)
        return component(.weekday, from: startOfMonth)
    }
    
    /// Returns an array of dates for all days in the specified month
    func daysInMonth(for date: Date) -> [Date] {
        let startOfMonth = date.startOfMonth(using: self)
        let numberOfDays = numberOfDaysInMonth(for: date)
        
        return (0..<numberOfDays).compactMap { dayOffset in
            self.date(byAdding: .day, value: dayOffset, to: startOfMonth)
        }
    }
    
    /// Returns an array of dates for a complete calendar month view (including prev/next month dates)
    func datesForCalendarMonth(containing date: Date) -> [Date] {
        let startOfMonth = date.startOfMonth(using: self)
        let firstWeekday = weekdayOfFirstDayInMonth(for: date)
        
        // Calculate how many days to go back to get to the start of the first week
        let daysToSubtract = (firstWeekday - self.firstWeekday + 7) % 7
        
        guard let calendarStartDate = self.date(byAdding: .day, value: -daysToSubtract, to: startOfMonth) else {
            return []
        }
        
        // Generate 42 dates (6 weeks × 7 days)
        return (0..<42).compactMap { dayOffset in
            self.date(byAdding: .day, value: dayOffset, to: calendarStartDate)
        }
    }
}

// MARK: - UIView Extensions

public extension UIView {
    
    /// Adds a subtle border to the view
    func addCalendarBorder(color: UIColor = .systemGray4, width: CGFloat = 0.5) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
    }
    
    /// Adds a shadow to the view
    func addCalendarShadow(color: UIColor = .black, 
                          opacity: Float = 0.1, 
                          offset: CGSize = CGSize(width: 0, height: 1), 
                          radius: CGFloat = 2) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    /// Rounds specific corners of the view
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, 
                               byRoundingCorners: corners, 
                               cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    /// Sets up the view for calendar cell appearance
    func configureAsCalendarCell() {
        layer.masksToBounds = true
        clipsToBounds = true
    }
}

// MARK: - UIColor Extensions

public extension UIColor {
    
    /// Creates a color from hex string
    convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        
        var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        guard hexSanitized.count == 6 || hexSanitized.count == 8 else {
            return nil
        }
        
        let scanner = Scanner(string: hexSanitized)
        var hexNumber: UInt64 = 0
        
        guard scanner.scanHexInt64(&hexNumber) else {
            return nil
        }
        
        if hexSanitized.count == 6 {
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
            b = CGFloat(hexNumber & 0x0000FF) / 255
            a = 1.0
        } else {
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000FF) / 255
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    /// Returns a hex string representation of the color
    func hexString() -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = components.count >= 4 ? Float(components[3]) : 1.0
        
        if a < 1.0 {
            return String(format: "#%02lX%02lX%02lX%02lX",
                         lroundf(r * 255),
                         lroundf(g * 255),
                         lroundf(b * 255),
                         lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX",
                         lroundf(r * 255),
                         lroundf(g * 255),
                         lroundf(b * 255))
        }
    }
    
    /// Returns a lighter version of the color
    func lighter(by percentage: CGFloat = 10.0) -> UIColor {
        return adjustBrightness(by: abs(percentage))
    }
    
    /// Returns a darker version of the color
    func darker(by percentage: CGFloat = 10.0) -> UIColor {
        return adjustBrightness(by: -abs(percentage))
    }
    
    /// Adjusts the brightness of the color
    private func adjustBrightness(by percentage: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness = max(min(brightness + percentage / 100.0, 1.0), 0.0)
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        
        return self
    }
}

// MARK: - Array Extensions

public extension Array where Element == Date {
    
    /// Filters dates to only include those in the specified month
    func datesInMonth(_ date: Date, using calendar: Calendar = Calendar.current) -> [Date] {
        return filter { $0.isSameMonth(as: date, using: calendar) }
    }
    
    /// Filters dates to only include those in the specified week
    func datesInWeek(_ date: Date, using calendar: Calendar = Calendar.current) -> [Date] {
        return filter { $0.isSameWeek(as: date, using: calendar) }
    }
    
    /// Groups dates by month
    func groupedByMonth(using calendar: Calendar = Calendar.current) -> [Date: [Date]] {
        return Dictionary(grouping: self) { date in
            date.startOfMonth(using: calendar)
        }
    }
}

// MARK: - NSAttributedString Extensions

public extension NSAttributedString {
    
    /// Creates an attributed string with the specified calendar text styling
    static func calendarText(_ text: String, 
                            font: UIFont, 
                            color: UIColor, 
                            alignment: NSTextAlignment = .center) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        return NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ])
    }
}

// MARK: - DateFormatter Extensions

public extension DateFormatter {
    
    /// Creates a formatter for calendar month display
    static func calendarMonthFormatter(locale: Locale = Locale.current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    /// Creates a formatter for calendar day display
    static func calendarDayFormatter(locale: Locale = Locale.current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "d"
        return formatter
    }
    
    /// Creates a formatter for weekday symbols
    static func weekdayFormatter(locale: Locale = Locale.current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        return formatter
    }
}
