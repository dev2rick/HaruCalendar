//
//  HaruCalendarCalculator.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit
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

public class HaruCalendarCalculator: NSObject {
    
    // MARK: - Properties
    
    weak var calendar: HaruCalendar?
    
    // MARK: - Private Properties
    
    private var numberOfMonths: Int = 0
    private var months: [Int: Date] = [:]
    private var monthHeads: [Int: Date] = [:]
    
    private var numberOfWeeks: Int = 0
    private var weeks: [Int: Date] = [:]
    private var rowCounts: [Date: Int] = [:]
    
    // MARK: - Computed Properties
    
    private var gregorian: Calendar {
        return calendar?.gregorian ?? Calendar.current
    }
    
    private var minimumDate: Date {
        return calendar?.minimumDate ?? Date.distantPast
    }
    
    private var maximumDate: Date {
        return calendar?.maximumDate ?? Date.distantFuture
    }
    
    public var numberOfSections: Int {
        guard let calendar = calendar else { return 0 }
        
        switch calendar.scope {
        case .month:
            return numberOfMonths
        case .week:
            return numberOfWeeks
        }
    }
    
    // MARK: - Initialization
    
    override public init() {
        super.init()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(calendar:) instead.")
        return nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Memory Management
    
    @objc private func didReceiveMemoryWarning() {
        months.removeAll()
        monthHeads.removeAll()
        weeks.removeAll()
        rowCounts.removeAll()
    }
    
    // MARK: - Public Methods
    
    public func safeDate(for date: Date) -> Date {
        if gregorian.compare(date, to: minimumDate, toGranularity: .day) == .orderedAscending {
            return minimumDate
        } else if gregorian.compare(date, to: maximumDate, toGranularity: .day) == .orderedDescending {
            return maximumDate
        }
        return date
    }
    
    public func date(for indexPath: IndexPath) -> Date? {
        guard let calendar = calendar else { return nil }
        return date(for: indexPath, scope: calendar.scope)
    }
    
    public func date(for indexPath: IndexPath, scope: HaruCalendarScope) -> Date? {
        switch scope {
        case .month:
            guard let head = monthHead(for: indexPath.section) else { return nil }
            return gregorian.date(byAdding: .day, value: indexPath.item, to: head)
            
        case .week:
            guard let currentPage = week(for: indexPath.section) else { return nil }
            return gregorian.date(byAdding: .day, value: indexPath.item, to: currentPage)
        }
    }
    
    public func indexPath(for date: Date) -> IndexPath? {
        guard let calendar = calendar else { return nil }
        return indexPath(for: date, at: .current, scope: calendar.scope)
    }
    
    public func indexPath(for date: Date, scope: HaruCalendarScope) -> IndexPath? {
        return indexPath(for: date, at: .current, scope: scope)
    }
    
    public func indexPath(for date: Date, at monthPosition: HaruCalendarMonthPosition) -> IndexPath? {
        guard let calendar = calendar else { return nil }
        return indexPath(for: date, at: monthPosition, scope: calendar.scope)
    }
    
    public func indexPath(for date: Date, at monthPosition: HaruCalendarMonthPosition, scope: HaruCalendarScope) -> IndexPath? {
        var item = 0
        var section = 0
        
        switch scope {
        case .month:
            guard let firstDayOfMinimum = gregorian.dateInterval(of: .month, for: minimumDate)?.start,
                  let firstDayOfDate = gregorian.dateInterval(of: .month, for: date)?.start else {
                return nil
            }
            
            let monthComponents = gregorian.dateComponents([.month], from: firstDayOfMinimum, to: firstDayOfDate)
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
            let dayComponents = gregorian.dateComponents([.day], from: head, to: date)
            item = dayComponents.day ?? 0
            
        case .week:
            guard let firstWeekOfMinimum = gregorian.dateInterval(of: .weekOfYear, for: minimumDate)?.start,
                  let firstWeekOfDate = gregorian.dateInterval(of: .weekOfYear, for: date)?.start else {
                return nil
            }
            
            let weekComponents = gregorian.dateComponents([.weekOfYear], from: firstWeekOfMinimum, to: firstWeekOfDate)
            section = weekComponents.weekOfYear ?? 0
            
            let weekday = gregorian.component(.weekday, from: date)
            item = ((weekday - gregorian.firstWeekday) + 7) % 7
        }
        
        guard item >= 0 && section >= 0 else { return nil }
        return IndexPath(item: item, section: section)
    }
    
    public func page(for section: Int) -> Date? {
        guard let calendar = calendar else { return nil }
        
        switch calendar.scope {
        case .week:
            guard let week = week(for: section) else { return nil }
            return gregorian.dateInterval(of: .weekOfYear, for: week)?.start
        case .month:
            return month(for: section)
        }
    }
    
    public func month(for section: Int) -> Date? {
        if let cached = months[section] {
            return cached
        }
        
        guard let firstDayOfMinimum = gregorian.dateInterval(of: .month, for: minimumDate)?.start,
              let month = gregorian.date(byAdding: .month, value: section, to: firstDayOfMinimum) else {
            return nil
        }
        
        let numberOfHeadPlaceholders = self.numberOfHeadPlaceholders(for: month)
        let monthHead = gregorian.date(byAdding: .day, value: -numberOfHeadPlaceholders, to: month)
        
        months[section] = month
        monthHeads[section] = monthHead
        
        return month
    }
    
    public func monthHead(for section: Int) -> Date? {
        if let cached = monthHeads[section] {
            return cached
        }
        
        guard let month = self.month(for: section) else { return nil }
        let numberOfHeadPlaceholders = self.numberOfHeadPlaceholders(for: month)
        let monthHead = gregorian.date(byAdding: .day, value: -numberOfHeadPlaceholders, to: month)
        
        monthHeads[section] = monthHead
        return monthHead
    }
    
    public func week(for section: Int) -> Date? {
        if let cached = weeks[section] {
            return cached
        }
        
        guard let firstWeekOfMinimum = gregorian.dateInterval(of: .weekOfYear, for: minimumDate)?.start,
              let week = gregorian.date(byAdding: .weekOfYear, value: section, to: firstWeekOfMinimum) else {
            return nil
        }
        
        weeks[section] = week
        return week
    }
    
    public func numberOfHeadPlaceholders(for month: Date) -> Int {
        guard let calendar = calendar else { return 0 }
        
        let currentWeekday = gregorian.component(.weekday, from: month)
        let firstWeekday = gregorian.firstWeekday
        var number = ((currentWeekday - firstWeekday) + 7) % 7
        
        // Handle special case for six rows placeholder
        if number == 0 && calendar.placeholderType.contains(.fillSixRows) {
            number = 7
        }
        
        return number
    }
    
    public func numberOfRows(in month: Date) -> Int {
        guard let calendar = calendar else { return 0 }
        
        if calendar.placeholderType.contains(.fillSixRows) {
            return 6
        }
        
        if let cached = rowCounts[month] {
            return cached
        }
        
        guard let firstDayOfMonth = gregorian.dateInterval(of: .month, for: month)?.start else {
            return 0
        }
        
        let weekdayOfFirstDay = gregorian.component(.weekday, from: firstDayOfMonth)
        let numberOfDaysInMonth = gregorian.range(of: .day, in: .month, for: month)?.count ?? 0
        let numberOfPlaceholdersForPrev = ((weekdayOfFirstDay - gregorian.firstWeekday) + 7) % 7
        let headDayCount = numberOfDaysInMonth + numberOfPlaceholdersForPrev
        let numberOfRows = (headDayCount / 7) + (headDayCount % 7 > 0 ? 1 : 0)
        
        rowCounts[month] = numberOfRows
        return numberOfRows
    }
    
    public func numberOfRows(in section: Int) -> Int {
        guard let calendar = calendar else { return 0 }
        
        if calendar.scope == .week {
            return 1
        }
        
        guard let month = month(for: section) else { return 0 }
        return numberOfRows(in: month)
    }
    
    public func monthPosition(for indexPath: IndexPath) -> HaruCalendarMonthPosition {
        guard let calendar = calendar else { return .notFound }
        
        if calendar.scope == .week {
            return .current
        }
        
        guard let date = self.date(for: indexPath),
              let month = month(for: indexPath.section) else {
            return .notFound
        }
        
        let comparison = gregorian.compare(date, to: month, toGranularity: .month)
        
        switch comparison {
        case .orderedAscending:
            return .previous
        case .orderedDescending:
            return .next
        case .orderedSame:
            return .current
        }
    }
    
    public func coordinate(for indexPath: IndexPath) -> HaruCalendarCoordinate {
        let row = indexPath.item / 7
        let column = indexPath.item % 7
        return HaruCalendarCoordinate(row: row, column: column)
    }
    
    public func reloadSections() {
        calculateNumberOfMonths()
        calculateNumberOfWeeks()
        
        // Clear caches
        months.removeAll()
        monthHeads.removeAll()
        weeks.removeAll()
        rowCounts.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func calculateNumberOfMonths() {
        guard let firstDayOfMinimum = gregorian.dateInterval(of: .month, for: minimumDate)?.start,
              let firstDayOfMaximum = gregorian.dateInterval(of: .month, for: maximumDate)?.start else {
            numberOfMonths = 0
            return
        }
        
        let components = gregorian.dateComponents([.month], from: firstDayOfMinimum, to: firstDayOfMaximum)
        numberOfMonths = (components.month ?? 0) + 1
    }
    
    private func calculateNumberOfWeeks() {
        guard let firstWeekOfMinimum = gregorian.dateInterval(of: .weekOfYear, for: minimumDate)?.start,
              let firstWeekOfMaximum = gregorian.dateInterval(of: .weekOfYear, for: maximumDate)?.start else {
            numberOfWeeks = 0
            return
        }
        
        let components = gregorian.dateComponents([.weekOfYear], from: firstWeekOfMinimum, to: firstWeekOfMaximum)
        numberOfWeeks = (components.weekOfYear ?? 0) + 1
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
}
