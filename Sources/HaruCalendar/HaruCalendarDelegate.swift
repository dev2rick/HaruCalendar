//
//  HaruCalendarDelegate.swift
//  HaruCalendar
//
//  Created by rick on 9/22/25.
//

import UIKit

public protocol HaruCalendarDelegate: AnyObject {
    func calendar(_ calendar: HaruCalendar, shouldSelect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool
    func calendar(_ calendar: HaruCalendar, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition)
    func calendar(_ calendar: HaruCalendar, shouldDeselect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool
    func calendar(_ calendar: HaruCalendar, didDeselect date: Date, at monthPosition: HaruCalendarMonthPosition)
    func calendar(_ calendar: HaruCalendar, boundingRectWillChange bounds: CGRect, animated: Bool)
    func calendar(_ calendar: HaruCalendar, willDisplay cell: HaruCalendarCell, for date: Date, at monthPosition: HaruCalendarMonthPosition)
    func calendarCurrentPageDidChange(_ calendar: HaruCalendar)
}

public extension HaruCalendarDelegate {
    func calendar(_ calendar: HaruCalendar, shouldSelect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool {
        return true
    }
    
    func calendar(_ calendar: HaruCalendar, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition) {
        
    }
    
    func calendar(_ calendar: HaruCalendar, shouldDeselect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool {
        return true
    }
    
    func calendar(_ calendar: HaruCalendar, didDeselect date: Date, at monthPosition: HaruCalendarMonthPosition) {
        
    }
    
    func calendar(_ calendar: HaruCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        
    }
    
    func calendar(_ calendar: HaruCalendar, willDisplay cell: HaruCalendarCell, for date: Date, at monthPosition: HaruCalendarMonthPosition) {
        
    }
    
    func calendarCurrentPageDidChange(_ calendar: HaruCalendar) {
        
    }
}

/// Protocol for customizing calendar appearance on a per-date basis
public protocol HaruCalendarDelegateAppearance: HaruCalendarDelegate {
    
    // Background Colors
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor?
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor?
    
    // Title colors
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor?
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, titleSelectionColorFor date: Date) -> UIColor?
    
    // Subtitle colors
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, subtitleDefaultColorFor date: Date) -> UIColor?
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, subtitleSelectionColorFor date: Date) -> UIColor?
    
    // Event colors
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]?
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, eventSelectionColorsFor date: Date) -> [UIColor]?
    
    // Border colors
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, borderDefaultColorFor date: Date) -> UIColor?
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, borderSelectionColorFor date: Date) -> UIColor?
    
    // Offsets
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, titleOffsetFor date: Date) -> CGPoint
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, subtitleOffsetFor date: Date) -> CGPoint
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, imageOffsetFor date: Date) -> CGPoint
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, eventOffsetFor date: Date) -> CGPoint
    
    // Border radius
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, borderRadiusFor date: Date) -> CGFloat
}

public extension HaruCalendarDelegateAppearance {
    
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        return nil
    }
    
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
        return nil
    }
    
    // Title colors
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        return nil
    }
    
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, titleSelectionColorFor date: Date) -> UIColor? {
        return nil
    }
    
    // Subtitle colors
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, subtitleDefaultColorFor date: Date) -> UIColor? {
        return nil
    }
    
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, subtitleSelectionColorFor date: Date) -> UIColor? {
        return nil
    }
    
    // Event colors
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
        return nil
    }
    
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, eventSelectionColorsFor date: Date) -> [UIColor]? {
        return nil
    }
    
    // Border colors
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, borderDefaultColorFor date: Date) -> UIColor? {
        return nil
    }
    
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, borderSelectionColorFor date: Date) -> UIColor? {
        return nil
    }
    
    // Offsets
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, titleOffsetFor date: Date) -> CGPoint {
        return .zero
    }
    
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, subtitleOffsetFor date: Date) -> CGPoint {
        return .zero
    }
    
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, imageOffsetFor date: Date) -> CGPoint {
        return .zero
    }
    
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, eventOffsetFor date: Date) -> CGPoint {
        return .zero
    }
    
    // Border radius
    func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, borderRadiusFor date: Date) -> CGFloat {
        return 0
    }
}
