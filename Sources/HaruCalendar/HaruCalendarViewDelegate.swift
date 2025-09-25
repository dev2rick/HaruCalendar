//
//  File.swift
//  HaruCalendarView
//
//  Created by rick on 9/25/25.
//

import UIKit

public protocol HaruCalendarViewDelegate: AnyObject {
    func calendar(_ calendar: HaruCalendarView, shouldSelect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool
    func calendar(_ calendar: HaruCalendarView, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition)
    func calendar(_ calendar: HaruCalendarView, shouldDeselect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool
    func calendar(_ calendar: HaruCalendarView, didDeselect date: Date, at monthPosition: HaruCalendarMonthPosition)
    func calendar(_ calendar: HaruCalendarView, boundingRectWillChange bounds: CGRect, animated: Bool)
    func calendar(_ calendar: HaruCalendarView, willDisplay cell: HaruCalendarCollectionViewCell, for date: Date, at monthPosition: HaruCalendarMonthPosition)
    func calendarCurrentPageDidChange(_ calendar: HaruCalendarView)
}

public extension HaruCalendarViewDelegate {
    func calendar(_ calendar: HaruCalendarView, shouldSelect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool {
        return true
    }
    
    func calendar(_ calendar: HaruCalendarView, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition) {
        
    }
    
    func calendar(_ calendar: HaruCalendarView, shouldDeselect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool {
        return true
    }
    
    func calendar(_ calendar: HaruCalendarView, didDeselect date: Date, at monthPosition: HaruCalendarMonthPosition) {
        
    }
    
    func calendar(_ calendar: HaruCalendarView, boundingRectWillChange bounds: CGRect, animated: Bool) {
        
    }
    
    func calendar(_ calendar: HaruCalendarView, willDisplay cell: HaruCalendarCollectionViewCell, for date: Date, at monthPosition: HaruCalendarMonthPosition) {
        
    }
    
    func calendarCurrentPageDidChange(_ calendar: HaruCalendarView) {
        
    }
}
