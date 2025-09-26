//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import Foundation

// MARK: - Coordinate Structure
public struct HaruCalendarCoordinate {
    public let row: Int
    public let column: Int
    
    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

// MARK: - HaruCalendarCalculator

public extension HaruCalendarView {
    
    // MARK: - Public Methods
    
    func safeDate(for date: Date) -> Date {
        if calendar.compare(date, to: minimumDate, toGranularity: .day) == .orderedAscending {
            return minimumDate
        } else if calendar.compare(date, to: maximumDate, toGranularity: .day) == .orderedDescending {
            return maximumDate
        }
        return date
    }
    
    func date(for indexPath: IndexPath) -> Date? {
        switch scope {
        case .month:
            guard let head = monthHead(for: indexPath.section) else { return nil }
            return calendar.date(byAdding: .day, value: indexPath.item, to: head)
            
        case .week:
            guard let currentPage = week(for: indexPath.section) else { return nil }
            return calendar.date(byAdding: .day, value: indexPath.item, to: currentPage)
        }
    }
    
    func indexPath(for date: Date, at monthPosition: HaruCalendarMonthPosition = .current, scope: HaruCalendarScope) -> IndexPath? {
        var item = 0
        var section = 0
        
        switch scope {
        case .month:
            guard let firstDayOfMinimum = calendar.dateInterval(of: .month, for: minimumDate)?.start,
                  let firstDayOfDate = calendar.dateInterval(of: .month, for: date)?.start else {
                return nil
            }
            
            let monthComponents = calendar.dateComponents([.month], from: firstDayOfMinimum, to: firstDayOfDate)
            section = monthComponents.month ?? 0
            
            switch monthPosition {
            case .previous:
                section += 1
            case .next:
                section -= 1
            default:
                break
            }
            
            guard let head = monthHead(for: section) else { return nil }
            let dayComponents = calendar.dateComponents([.day], from: head, to: date)
            item = dayComponents.day ?? 0
            
        case .week:
            guard let firstWeekOfMinimum = calendar.dateInterval(of: .weekOfYear, for: minimumDate)?.start,
                  let firstWeekOfDate = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
                return nil
            }
            
            let weekComponents = calendar.dateComponents([.weekOfYear], from: firstWeekOfMinimum, to: firstWeekOfDate)
            section = weekComponents.weekOfYear ?? 0
            
            let weekday = calendar.component(.weekday, from: date)
            item = ((weekday - calendar.firstWeekday) + 7) % 7
        }
        
        guard item >= 0 && section >= 0 else { return nil }
        return IndexPath(item: item, section: section)
    }
    
    func page(for section: Int) -> Date? {
        switch scope {
        case .week:
            guard let week = week(for: section) else { return nil }
            return calendar.dateInterval(of: .weekOfYear, for: week)?.start
        case .month:
            return month(for: section)
        }
    }
    
    func month(for section: Int) -> Date? {
        if let cached = months[section] {
            return cached
        }
        
        guard
            let firstDayOfMinimum = calendar.dateInterval(of: .month, for: minimumDate)?.start,
            let month = calendar.date(byAdding: .month, value: section, to: firstDayOfMinimum) else {
            return nil
        }
        
        let numberOfHeadPlaceholders = self.numberOfHeadPlaceholders(for: month)
        let monthHead = calendar.date(byAdding: .day, value: -numberOfHeadPlaceholders, to: month)
        
        months[section] = month
        monthHeads[section] = monthHead
        
        return month
    }
    
    func monthHead(for section: Int) -> Date? {
        if let cached = monthHeads[section] {
            return cached
        }
        
        guard let month = self.month(for: section) else { return nil }
        let numberOfHeadPlaceholders = self.numberOfHeadPlaceholders(for: month)
        let monthHead = calendar.date(byAdding: .day, value: -numberOfHeadPlaceholders, to: month)
        
        monthHeads[section] = monthHead
        return monthHead
    }
    
    func week(for section: Int) -> Date? {
        if let cached = weeks[section] {
            return cached
        }
        
        guard let firstWeekOfMinimum = calendar.dateInterval(of: .weekOfYear, for: minimumDate)?.start,
              let week = calendar.date(byAdding: .weekOfYear, value: section, to: firstWeekOfMinimum) else {
            return nil
        }
        
        weeks[section] = week
        return week
    }
    
    func numberOfHeadPlaceholders(for month: Date) -> Int {
        
        let currentWeekday = calendar.component(.weekday, from: month)
        let firstWeekday = calendar.firstWeekday
        let number = ((currentWeekday - firstWeekday) + 7) % 7
        
        if number == .zero {
            return 7
        }
        
        return number
    }
    
    
    func monthPosition(for indexPath: IndexPath) -> HaruCalendarMonthPosition {
        guard scope == .month else { return .current }
        
        guard
            let date = self.date(for: indexPath),
            let month = month(for: indexPath.section) else {
            return .notFound
        }
        
        let comparison = calendar.compare(date, to: month, toGranularity: .month)
        
        switch comparison {
        case .orderedAscending:
            return .previous
        case .orderedDescending:
            return .next
        case .orderedSame:
            return .current
        }
    }
    
    func coordinate(for indexPath: IndexPath) -> HaruCalendarCoordinate {
        let row = indexPath.item / 7
        let column = indexPath.item % 7
        return HaruCalendarCoordinate(row: row, column: column)
    }
    
    internal func calculateNumberOfMonths() -> Int {
        guard
            let firstDayOfMinimum = calendar.dateInterval(of: .month, for: minimumDate)?.start,
            let firstDayOfMaximum = calendar.dateInterval(of: .month, for: maximumDate)?.start,
            let month = calendar.dateComponents([.month], from: firstDayOfMinimum, to: firstDayOfMaximum).month
        else {
            return 0
        }
        
        return month + 1
    }
    
    internal func calculateNumberOfWeeks() -> Int {
        guard
            let firstWeekOfMinimum = calendar.dateInterval(of: .weekOfYear, for: minimumDate)?.start,
            let firstWeekOfMaximum = calendar.dateInterval(of: .weekOfYear, for: maximumDate)?.start,
            let weekOfYear = calendar.dateComponents([.weekOfYear], from: firstWeekOfMinimum, to: firstWeekOfMaximum).weekOfYear
        else {
            return 0
        }
        return weekOfYear + 1
    }
}

// MARK: - Date Utilities

extension Calendar {
    func firstDayOfWeek(for date: Date) -> Date? {
        return dateInterval(of: .weekOfYear, for: date)?.start
    }
    
    func firstDayOfMonth(for date: Date) -> Date? {
        return dateInterval(of: .month, for: date)?.start
    }
    
    func middleDayOfWeek(_ week: Date) -> Date? {
        
        let weekdayComponents = dateComponents([.weekday], from: week)
        guard let weekday = weekdayComponents.weekday else { return nil }
        
        var componentsToSubtract = DateComponents()
        componentsToSubtract.day = -(weekday - firstWeekday) + 3
        
        // Fix https://github.com/WenchaoD/FSCalendar/issues/1100 and https://github.com/WenchaoD/FSCalendar/issues/1102
        // If firstWeekday is not 1, and weekday is less than firstWeekday, the middleDayOfWeek will be the middle day of next week
        if weekday < firstWeekday {
            componentsToSubtract.day = (componentsToSubtract.day ?? 0) - 7
        }
        
        guard let middleDayOfWeek = date(byAdding: componentsToSubtract, to: week) else { return nil }
        
        let components = dateComponents([.year, .month, .day, .hour], from: middleDayOfWeek)
        let normalizedDate = date(from: components)
        
        return normalizedDate
    }

}
