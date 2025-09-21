//
//  HaruCalendarAppearance.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - Cell State

public enum HaruCalendarCellState: CaseIterable {
    case normal
    case selected
    case placeholder
    case disabled
    case today
    case weekend
    
    public static let todaySelected: [HaruCalendarCellState] = [.today, .selected]
}

// MARK: - Separators

public struct HaruCalendarSeparators: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let none = HaruCalendarSeparators([])
    public static let interRows = HaruCalendarSeparators(rawValue: 1 << 0)
}

// MARK: - Case Options

public struct HaruCalendarCaseOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    // Header options
    public static let headerUsesDefaultCase = HaruCalendarCaseOptions([])
    public static let headerUsesUpperCase = HaruCalendarCaseOptions(rawValue: 1 << 0)
    public static let headerUsesCapitalized = HaruCalendarCaseOptions(rawValue: 1 << 1)
    
    // Weekday options
    public static let weekdayUsesDefaultCase = HaruCalendarCaseOptions([])
    public static let weekdayUsesUpperCase = HaruCalendarCaseOptions(rawValue: 1 << 4)
    public static let weekdayUsesSingleUpperCase = HaruCalendarCaseOptions(rawValue: 2 << 4)
}

// MARK: - HaruCalendarAppearance

public class HaruCalendarAppearance: NSObject {
    
    // MARK: - Internal Properties
    
    weak var calendar: HaruCalendar?
    
    // MARK: - Color Dictionaries
    
    public var backgroundColors: [HaruCalendarCellState: UIColor] = [:]
    public var titleColors: [HaruCalendarCellState: UIColor] = [:]
    public var subtitleColors: [HaruCalendarCellState: UIColor] = [:]
    public var borderColors: [HaruCalendarCellState: UIColor] = [:]
    
    // MARK: - Font Properties
    
    public var titleFont: UIFont = UIFont.systemFont(ofSize: HaruCalendarConstants.standardTitleTextSize) {
        didSet {
            if titleFont != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var subtitleFont: UIFont = UIFont.systemFont(ofSize: HaruCalendarConstants.standardSubtitleTextSize) {
        didSet {
            if subtitleFont != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var weekdayFont: UIFont = UIFont.systemFont(ofSize: HaruCalendarConstants.standardWeekdayTextSize) {
        didSet {
            if weekdayFont != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var headerTitleFont: UIFont = UIFont.systemFont(ofSize: HaruCalendarConstants.standardHeaderTextSize) {
        didSet {
            if headerTitleFont != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    // MARK: - Offset Properties
    
    public var headerTitleOffset: CGPoint = .zero {
        didSet {
            if headerTitleOffset != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var titleOffset: CGPoint = .zero {
        didSet {
            if titleOffset != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var subtitleOffset: CGPoint = .zero {
        didSet {
            if subtitleOffset != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var eventOffset: CGPoint = .zero {
        didSet {
            if eventOffset != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var imageOffset: CGPoint = .zero {
        didSet {
            if imageOffset != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    // MARK: - Event Colors
    
    public var eventDefaultColor: UIColor = HaruCalendarConstants.standardEventDotColor {
        didSet {
            if eventDefaultColor != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var eventSelectionColor: UIColor = HaruCalendarConstants.standardEventDotColor {
        didSet {
            if eventSelectionColor != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    // MARK: - Text Colors
    
    public var weekdayTextColor: UIColor = HaruCalendarConstants.standardTitleTextColor {
        didSet {
            if weekdayTextColor != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var headerTitleColor: UIColor = HaruCalendarConstants.standardTitleTextColor {
        didSet {
            if headerTitleColor != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var headerSeparatorColor: UIColor = HaruCalendarConstants.standardLineColor {
        didSet {
            if headerSeparatorColor != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    // MARK: - Header Properties
    
    public var headerDateFormat: String = "MMMM yyyy" {
        didSet {
            if headerDateFormat != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var headerTitleAlignment: NSTextAlignment = .center {
        didSet {
            if headerTitleAlignment != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var headerMinimumDissolvedAlpha: CGFloat = 0.2 {
        didSet {
            if headerMinimumDissolvedAlpha != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    // MARK: - Individual Color Properties
    
    public var titleDefaultColor: UIColor {
        get { return titleColors[.normal] ?? .black }
        set { 
            titleColors[.normal] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var titleSelectionColor: UIColor {
        get { return titleColors[.selected] ?? .white }
        set { 
            titleColors[.selected] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var titleTodayColor: UIColor {
        get { return titleColors[.today] ?? .white }
        set { 
            titleColors[.today] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var titlePlaceholderColor: UIColor {
        get { return titleColors[.placeholder] ?? .lightGray }
        set { 
            titleColors[.placeholder] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var titleWeekendColor: UIColor {
        get { return titleColors[.weekend] ?? titleDefaultColor }
        set { 
            titleColors[.weekend] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var subtitleDefaultColor: UIColor {
        get { return subtitleColors[.normal] ?? .darkGray }
        set { 
            subtitleColors[.normal] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var subtitleSelectionColor: UIColor {
        get { return subtitleColors[.selected] ?? .white }
        set { 
            subtitleColors[.selected] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var subtitleTodayColor: UIColor {
        get { return subtitleColors[.today] ?? .white }
        set { 
            subtitleColors[.today] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var subtitlePlaceholderColor: UIColor {
        get { return subtitleColors[.placeholder] ?? .lightGray }
        set { 
            subtitleColors[.placeholder] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var subtitleWeekendColor: UIColor {
        get { return subtitleColors[.weekend] ?? subtitleDefaultColor }
        set { 
            subtitleColors[.weekend] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var selectionColor: UIColor {
        get { return backgroundColors[.selected] ?? HaruCalendarConstants.standardSelectionColor }
        set { 
            backgroundColors[.selected] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var todayColor: UIColor {
        get { return backgroundColors[.today] ?? HaruCalendarConstants.standardTodayColor }
        set { 
            backgroundColors[.today] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var todaySelectionColor: UIColor {
        get { 
            // Combined state for today + selected
            return backgroundColors[.selected] ?? selectionColor
        }
        set { 
            backgroundColors[.selected] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var borderDefaultColor: UIColor? {
        get { return borderColors[.normal] }
        set { 
            borderColors[.normal] = newValue
            calendar?.configureAppearance()
        }
    }
    
    public var borderSelectionColor: UIColor? {
        get { return borderColors[.selected] }
        set { 
            borderColors[.selected] = newValue
            calendar?.configureAppearance()
        }
    }
    
    // MARK: - Border Properties
    
    public var borderRadius: CGFloat = 1.0 {
        didSet {
            if borderRadius != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    // MARK: - Style Options
    
    public var caseOptions: HaruCalendarCaseOptions = [.headerUsesDefaultCase, .weekdayUsesDefaultCase] {
        didSet {
            if caseOptions != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    public var separators: HaruCalendarSeparators = .none {
        didSet {
            if separators != oldValue {
                calendar?.configureAppearance()
            }
        }
    }
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        setupDefaultColors()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init() instead.")
        return nil
    }
    
    // MARK: - Setup
    
    private func setupDefaultColors() {
        // Background colors
        backgroundColors[.normal] = .clear
        backgroundColors[.selected] = HaruCalendarConstants.standardSelectionColor
        backgroundColors[.disabled] = .clear
        backgroundColors[.placeholder] = .clear
        backgroundColors[.today] = HaruCalendarConstants.standardTodayColor
        
        // Title colors
        titleColors[.normal] = .black
        titleColors[.selected] = .white
        titleColors[.disabled] = .gray
        titleColors[.placeholder] = .lightGray
        titleColors[.today] = .white
        
        // Subtitle colors
        subtitleColors[.normal] = .darkGray
        subtitleColors[.selected] = .white
        subtitleColors[.disabled] = .lightGray
        subtitleColors[.placeholder] = .lightGray
        subtitleColors[.today] = .white
        
        // Border colors
        borderColors[.normal] = .clear
        borderColors[.selected] = .clear
    }
}

// MARK: - Color Utilities

public extension HaruCalendarAppearance {
    
    func colorForState(_ state: HaruCalendarCellState, in colorDictionary: [HaruCalendarCellState: UIColor]) -> UIColor? {
        // Handle combined states (today + selected)
        if state == .selected {
            // Check for today + selected combination
            if let todaySelectedColor = colorDictionary[.selected] {
                return todaySelectedColor
            }
        }
        
        if state == .today {
            if let todayColor = colorDictionary[.today] {
                return todayColor
            }
        }
        
        if state == .placeholder {
            if let placeholderColor = colorDictionary[.placeholder] {
                return placeholderColor
            }
        }
        
        if state == .weekend {
            if let weekendColor = colorDictionary[.weekend] {
                return weekendColor
            }
        }
        
        return colorDictionary[.normal]
    }
    
    func titleColor(for state: HaruCalendarCellState) -> UIColor? {
        return colorForState(state, in: titleColors)
    }
    
    func subtitleColor(for state: HaruCalendarCellState) -> UIColor? {
        return colorForState(state, in: subtitleColors)
    }
    
    func backgroundColor(for state: HaruCalendarCellState) -> UIColor? {
        return colorForState(state, in: backgroundColors)
    }
    
    func borderColor(for state: HaruCalendarCellState) -> UIColor? {
        return colorForState(state, in: borderColors)
    }
}
