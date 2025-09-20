//
//  HaruCalendarTypes.swift
//  HaruCalendar
//
//  Created by rick on 9/20/25.
//

import UIKit
import Foundation

// MARK: - Calendar Scope

public enum HaruCalendarScope: CaseIterable {
    case month
    case week
}

// MARK: - Scroll Direction

public enum HaruCalendarScrollDirection: CaseIterable {
    case vertical
    case horizontal
}

// MARK: - Placeholder Type

public struct HaruCalendarPlaceholderType: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = HaruCalendarPlaceholderType([])
    public static let fillHeadTail = HaruCalendarPlaceholderType(rawValue: 1 << 0)
    public static let fillSixRows = HaruCalendarPlaceholderType(rawValue: 1 << 1)
}

// MARK: - Month Position

public enum HaruCalendarMonthPosition: CaseIterable {
    case previous
    case current
    case next
    case notFound
}

// MARK: - Selection Mode

public enum HaruCalendarSelectionMode: CaseIterable {
    case none
    case single
    case multiple
}

// MARK: - Cell State

public struct HaruCalendarCellState {
    public let date: Date
    public let monthPosition: HaruCalendarMonthPosition
    public let isSelected: Bool
    public let isToday: Bool
    public let isWeekend: Bool
    public let isPlaceholder: Bool

    public init(
        date: Date,
        monthPosition: HaruCalendarMonthPosition,
        isSelected: Bool = false,
        isToday: Bool = false,
        isWeekend: Bool = false,
        isPlaceholder: Bool = false
    ) {
        self.date = date
        self.monthPosition = monthPosition
        self.isSelected = isSelected
        self.isToday = isToday
        self.isWeekend = isWeekend
        self.isPlaceholder = isPlaceholder
    }
}

// MARK: - Event Info

public struct HaruCalendarEventInfo {
    public let date: Date
    public let numberOfEvents: Int
    public let eventColors: [UIColor]

    public init(date: Date, numberOfEvents: Int, eventColors: [UIColor] = []) {
        self.date = date
        self.numberOfEvents = numberOfEvents
        self.eventColors = eventColors
    }
}

// MARK: - Animation Configuration

public struct HaruCalendarAnimationConfiguration {
    public let duration: TimeInterval
    public let dampingRatio: CGFloat
    public let velocity: CGFloat
    public let options: UIView.AnimationOptions

    public init(
        duration: TimeInterval = 0.3,
        dampingRatio: CGFloat = 0.8,
        velocity: CGFloat = 0.0,
        options: UIView.AnimationOptions = [.curveEaseInOut]
    ) {
        self.duration = duration
        self.dampingRatio = dampingRatio
        self.velocity = velocity
        self.options = options
    }

    public static let `default` = HaruCalendarAnimationConfiguration()
    public static let bounce = HaruCalendarAnimationConfiguration(
        duration: HaruCalendarConstants.defaultBounceAnimationDuration,
        dampingRatio: 0.6
    )
}

// MARK: - Layout Information

public struct HaruCalendarLayoutInfo {
    public let contentSize: CGSize
    public let headerHeight: CGFloat
    public let weekdayHeight: CGFloat
    public let rowHeight: CGFloat
    public let numberOfRows: Int

    public init(
        contentSize: CGSize,
        headerHeight: CGFloat,
        weekdayHeight: CGFloat,
        rowHeight: CGFloat,
        numberOfRows: Int
    ) {
        self.contentSize = contentSize
        self.headerHeight = headerHeight
        self.weekdayHeight = weekdayHeight
        self.rowHeight = rowHeight
        self.numberOfRows = numberOfRows
    }
}

// MARK: - Date Range

public struct HaruCalendarDateRange {
    public let startDate: Date
    public let endDate: Date

    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }

    public var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }

    public func contains(_ date: Date) -> Bool {
        return date >= startDate && date <= endDate
    }
}

// MARK: - Error Types

public enum HaruCalendarError: Error, LocalizedError {
    case invalidDateRange
    case invalidConfiguration
    case cellRegistrationFailed
    case invalidArguments(String)

    public var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return "Invalid date range provided"
        case .invalidConfiguration:
            return "Invalid calendar configuration"
        case .cellRegistrationFailed:
            return "Failed to register calendar cell"
        case .invalidArguments(let message):
            return "Invalid arguments: \(message)"
        }
    }
}

// MARK: - Weak Reference Helper

public struct WeakReference<T: AnyObject> {
    private weak var _value: T?

    public var value: T? {
        return _value
    }

    public init(_ value: T?) {
        self._value = value
    }
}

// MARK: - Result Types

public typealias HaruCalendarCompletion = () -> Void
public typealias HaruCalendarDateCompletion = (Date) -> Void
public typealias HaruCalendarDatesCompletion = ([Date]) -> Void
public typealias HaruCalendarErrorCompletion = (HaruCalendarError?) -> Void
public typealias HaruCalendarBoundsChangeCompletion = (CGRect, Bool) -> Void
