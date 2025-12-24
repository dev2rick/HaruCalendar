//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

@MainActor
public protocol HaruCalendarViewDataSource: AnyObject {
    func heightForRow(_ calendar: HaruCalendarView) -> CGFloat?

    /// Provides a custom cell for the calendar at the given date
    /// - Parameters:
    ///   - calendar: The calendar view requesting the cell
    ///   - date: The date for which to provide the cell
    ///   - indexPath: The index path for the cell
    /// - Returns: A configured cell conforming to HaruCalendarCell
    func calendar(_ calendar: HaruCalendarView, cellForItemAt date: Date, at indexPath: IndexPath) -> (any HaruCalendarCell)
}

public extension HaruCalendarViewDataSource {
    func heightForRow(_ calendar: HaruCalendarView) -> CGFloat? {
        return 50 // default height for row
    }
}
