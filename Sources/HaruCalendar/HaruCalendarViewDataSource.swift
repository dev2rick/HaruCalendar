//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

public protocol HaruCalendarViewDataSource: AnyObject {
    func heightForRow(_ calendar: HaruCalendarView) -> CGFloat?
}

public extension HaruCalendarViewDataSource {
    func heightForRow(_ calendar: HaruCalendarView) -> CGFloat? {
        return 50 // default height for row
    }
}
