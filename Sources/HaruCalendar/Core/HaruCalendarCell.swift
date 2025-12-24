//
//  HaruCalendarCell.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

public protocol HaruCalendarCell: UICollectionViewCell {
    /// Configure the cell with calendar-specific data
    /// - Parameters:
    ///   - date: The date this cell represents
    ///   - monthPosition: Position relative to current month (previous/current/next)
    ///   - scope: Current calendar scope (month/week)
    func configure(date: Date, monthPosition: HaruCalendarMonthPosition, scope: HaruCalendarScope)

    /// Update the cell's selection state
    /// - Parameter selected: Whether the cell is selected
    func setCalendarSelected(_ selected: Bool)

    /// Update the cell's appearance (called during transitions/layout changes)
    func updateAppearance()
}
