//
//  HaruCalendarDataSource.swift
//  HaruCalendar
//
//  Created by rick on 9/22/25.
//

import UIKit

public protocol HaruCalendarDataSource: AnyObject {
    
    func calendar(_ calendar: HaruCalendar, titleFor date: Date) -> String?
    func calendar(_ calendar: HaruCalendar, subtitleFor date: Date) -> String?
    func calendar(_ calendar: HaruCalendar, imageFor date: Date) -> UIImage?
    func minimumDate(for calendar: HaruCalendar) -> Date
    func maximumDate(for calendar: HaruCalendar) -> Date
    func calendar(_ calendar: HaruCalendar, cellFor date: Date, at monthPosition: HaruCalendarMonthPosition) -> HaruCalendarCell
    func calendar(_ calendar: HaruCalendar, numberOfEventsFor date: Date) -> Int
}

public extension HaruCalendarDataSource {
    func calendar(_ calendar: HaruCalendar, titleFor date: Date) -> String? {
        return nil
    }
    
    func calendar(_ calendar: HaruCalendar, subtitleFor date: Date) -> String? {
        return nil
    }
    
    func calendar(_ calendar: HaruCalendar, imageFor date: Date) -> UIImage? {
        return nil
    }
    
    func minimumDate(for calendar: HaruCalendar) -> Date {
        return calendar.gregorian.date(byAdding: .year, value: -10, to: Date()) ?? .distantPast
    }
    
    func maximumDate(for calendar: HaruCalendar) -> Date {
        return calendar.gregorian.date(byAdding: .year, value: 10, to: Date()) ?? .distantFuture
    }
    
    func calendar(_ calendar: HaruCalendar, cellFor date: Date, at monthPosition: HaruCalendarMonthPosition) -> HaruCalendarCell {
        HaruCalendarCell()
    }
    
    func calendar(_ calendar: HaruCalendar, numberOfEventsFor date: Date) -> Int {
        return 0
    }
}
