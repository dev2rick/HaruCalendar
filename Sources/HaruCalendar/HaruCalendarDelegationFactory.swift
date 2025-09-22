//
//  HaruCalendarDelegationFactory.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import Foundation
import UIKit

// MARK: - HaruCalendarDelegationFactory

/// Factory class for creating delegation proxies with proper protocol configuration
public class HaruCalendarDelegationFactory: NSObject {
    
    // MARK: - Factory Methods
    
    /// Creates a delegation proxy for HaruCalendarDataSource
    /// - Returns: Configured proxy for data source delegation
    public static func dataSourceProxy() -> HaruCalendarDelegationProxy {
        return HaruCalendarDelegationProxy.dataSourceProxy()
    }
    
    /// Creates a delegation proxy for HaruCalendarDelegate
    /// - Returns: Configured proxy for delegate delegation
    public static func delegateProxy() -> HaruCalendarDelegationProxy {
        return HaruCalendarDelegationProxy.delegateProxy()
    }
    
    /// Creates a delegation proxy for HaruCalendarDelegateAppearance
    /// - Returns: Configured proxy for appearance delegate delegation
    public static func appearanceDelegateProxy() -> HaruCalendarDelegationProxy {
        return HaruCalendarDelegationProxy.appearanceDelegateProxy()
    }
}

// MARK: - Protocol Definitions

/// Protocol for providing data to the calendar
@objc public protocol HaruCalendarDataSource: NSObjectProtocol {
    
    @objc optional func calendar(_ calendar: HaruCalendar, titleFor date: Date) -> String?
    @objc optional func calendar(_ calendar: HaruCalendar, subtitleFor date: Date) -> String?
    @objc optional func calendar(_ calendar: HaruCalendar, imageFor date: Date) -> UIImage?
    @objc optional func minimumDate(for calendar: HaruCalendar) -> Date
    @objc optional func maximumDate(for calendar: HaruCalendar) -> Date
    @objc optional func calendar(_ calendar: HaruCalendar, cellFor date: Date, at monthPosition: HaruCalendarMonthPosition) -> HaruCalendarCell
    @objc optional func calendar(_ calendar: HaruCalendar, numberOfEventsFor date: Date) -> Int
}

/// Protocol for handling calendar events and user interactions
@objc public protocol HaruCalendarDelegate: NSObjectProtocol {
    
    @objc optional func calendar(_ calendar: HaruCalendar, shouldSelect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool
    @objc optional func calendar(_ calendar: HaruCalendar, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition)
    @objc optional func calendar(_ calendar: HaruCalendar, shouldDeselect date: Date, at monthPosition: HaruCalendarMonthPosition) -> Bool
    @objc optional func calendar(_ calendar: HaruCalendar, didDeselect date: Date, at monthPosition: HaruCalendarMonthPosition)
    @objc optional func calendar(_ calendar: HaruCalendar, boundingRectWillChange bounds: CGRect, animated: Bool)
    @objc optional func calendar(_ calendar: HaruCalendar, willDisplay cell: HaruCalendarCell, for date: Date, at monthPosition: HaruCalendarMonthPosition)
    @objc optional func calendarCurrentPageDidChange(_ calendar: HaruCalendar)
}

/// Protocol for customizing calendar appearance on a per-date basis
@objc public protocol HaruCalendarDelegateAppearance: HaruCalendarDelegate {
    
    // Fill colors
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor?
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor?
    
    // Title colors
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor?
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, titleSelectionColorFor date: Date) -> UIColor?
    
    // Subtitle colors
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, subtitleDefaultColorFor date: Date) -> UIColor?
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, subtitleSelectionColorFor date: Date) -> UIColor?
    
    // Event colors
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]?
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, eventSelectionColorsFor date: Date) -> [UIColor]?
    
    // Border colors
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, borderDefaultColorFor date: Date) -> UIColor?
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, borderSelectionColorFor date: Date) -> UIColor?
    
    // Offsets
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, titleOffsetFor date: Date) -> CGPoint
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, subtitleOffsetFor date: Date) -> CGPoint
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, imageOffsetFor date: Date) -> CGPoint
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, eventOffsetFor date: Date) -> CGPoint
    
    // Border radius
    @objc optional func calendar(_ calendar: HaruCalendar, appearance: HaruCalendarAppearance, borderRadiusFor date: Date) -> CGFloat
}

// MARK: - Deprecation Setup Extensions

private extension HaruCalendarDelegationProxy {
    
    func setupDataSourceDeprecations() {
        // Add future deprecation mappings here
        // Example: deprecations["calendar:titleForDate:"] = "calendar:titleFor:"
    }
    
    func setupDelegateDeprecations() {
        // Add future deprecation mappings here
        // Example: deprecations["calendar:didSelectDate:"] = "calendar:didSelect:"
    }
    
    func setupAppearanceDelegateDeprecations() {
        // Add future deprecation mappings here
        // Example: deprecations["calendar:appearance:fillColorForDate:"] = "calendar:appearance:fillDefaultColorFor:"
    }
}

// MARK: - Delegation Helper

/// Helper class for managing delegation relationships
public class HaruCalendarDelegationHelper: NSObject {
    
    // MARK: - Properties
    
    private let _dataSourceProxy: HaruCalendarDelegationProxy
    private let _delegateProxy: HaruCalendarDelegationProxy
    
    weak var dataSource: HaruCalendarDataSource? {
        get { return _dataSourceProxy.delegation as? HaruCalendarDataSource }
        set { _dataSourceProxy.delegation = newValue }
    }
    
    weak var delegate: HaruCalendarDelegate? {
        get { return _delegateProxy.delegation as? HaruCalendarDelegate }
        set { _delegateProxy.delegation = newValue }
    }
    
    // MARK: - Initialization
    
    public override init() {
        self._dataSourceProxy = HaruCalendarDelegationFactory.dataSourceProxy()
        self._delegateProxy = HaruCalendarDelegationFactory.delegateProxy()
        super.init()
    }
    
    // MARK: - Proxy Access
    
    public func dataSourceProxy() -> HaruCalendarDelegationProxy {
        return _dataSourceProxy
    }
    
    public func delegateProxy() -> HaruCalendarDelegationProxy {
        return _delegateProxy
    }
}
