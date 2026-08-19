//
//  HaruCalendarWeekdayView.swift
//  HaruCalendar
//
//  Created by rick on 10/1/25.
//

import UIKit

/// A view that displays the weekday header above the calendar grid.
///
/// Adopt this protocol to provide a fully custom header to `HaruCalendarView`
/// via `init(scope:weekdayView:)` or `setWeekdayView(_:)`.
@MainActor
public protocol HaruCalendarWeekdayView: UIView {

    /// Configure the header for the calendar in use.
    ///
    /// Called whenever the calendar view needs the header to reflect the
    /// current `Calendar` (locale, `firstWeekday`, symbols).
    /// - Parameter calendar: The calendar backing the grid.
    func configure(calendar: Calendar)

    /// Height reserved for the header.
    ///
    /// `HaruCalendarView` adds this to its `intrinsicContentSize`. Call
    /// `invalidateIntrinsicContentSize()` on the calendar view after changing it.
    var weekdayHeight: CGFloat { get }
}

public extension HaruCalendarWeekdayView {
    var weekdayHeight: CGFloat {
        let height = intrinsicContentSize.height
        return height > 0 ? height : bounds.height
    }
}
