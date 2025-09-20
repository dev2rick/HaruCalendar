//
//  HaruCalendarConstants.swift
//  HaruCalendar
//
//  Created by rick on 9/20/25.
//

import Foundation
import UIKit


// MARK: - Layout Constants

public struct HaruCalendarConstants {
    
    // MARK: - Dimensions
    public static let standardHeaderHeight: CGFloat = 40
    public static let standardWeekdayHeight: CGFloat = 25
    public static let standardMonthlyPageHeight: CGFloat = 300.0
    public static let standardWeeklyPageHeight: CGFloat = 108 + 1/3.0
    public static let standardCellDiameter: CGFloat = 100/3.0
    public static let standardSeparatorThickness: CGFloat = 0.5
    public static let automaticDimension: CGFloat = -1
    public static let defaultBounceAnimationDuration: CGFloat = 0.15
    public static let standardRowHeight: CGFloat = 38
    
    // MARK: - Text Sizes
    public static let standardTitleTextSize: CGFloat = 13.5
    public static let standardSubtitleTextSize: CGFloat = 10
    public static let standardWeekdayTextSize: CGFloat = 14
    public static let standardHeaderTextSize: CGFloat = 16.5
    
    // MARK: - Event Constants
    public static let maximumEventDotDiameter: CGFloat = 4.8
    public static let defaultHourComponent: Int = 0
    public static let maximumNumberOfEvents: Int = 3
    
    // MARK: - Identifiers
    public static let defaultCellReuseIdentifier = "_HaruCalendarDefaultCellReuseIdentifier"
    public static let blankCellReuseIdentifier = "_HaruCalendarBlankCellReuseIdentifier"
    public static let invalidArgumentsExceptionName = "Invalid argument exception"
    
    // MARK: - Special Values
    public static let pointInfinity = CGPoint(
        x: CGFloat.greatestFiniteMagnitude,
        y: CGFloat.greatestFiniteMagnitude
    )
    
    public static let sizeAutomatic = CGSize(
        width: automaticDimension,
        height: automaticDimension
    )
}

// MARK: - Color Constants

public extension HaruCalendarConstants {
    static let standardSelectionColor = UIColor(red: 31/255.0, green: 119/255.0, blue: 219/255.0, alpha: 1.0)
    static let standardTodayColor = UIColor(red: 198/255.0, green: 51/255.0, blue: 42/255.0, alpha: 1.0)
    static let standardTitleTextColor = UIColor(red: 14/255.0, green: 69/255.0, blue: 221/255.0, alpha: 1.0)
    static let standardEventDotColor = UIColor(red: 31/255.0, green: 119/255.0, blue: 219/255.0, alpha: 0.75)
    
    static let standardLineColor = UIColor.lightGray.withAlphaComponent(0.30)
    static let standardSeparatorColor = UIColor.lightGray.withAlphaComponent(0.60)
}

// MARK: - Device Detection

public extension HaruCalendarConstants {
    static var deviceIsIPad: Bool {
        return UIDevice.current.model.hasPrefix("iPad")
    }
    
    static var isInAppExtension: Bool {
        return Bundle.main.bundlePath.hasSuffix(".appex")
    }
}

// MARK: - Math Utilities

public extension HaruCalendarConstants {
    static func floor(_ value: CGFloat) -> CGFloat {
        return Foundation.floor(value)
    }
    
    static func round(_ value: CGFloat) -> CGFloat {
        return Foundation.round(value)
    }
    
    static func ceil(_ value: CGFloat) -> CGFloat {
        return Foundation.ceil(value)
    }
    
    static func mod(_ dividend: CGFloat, _ divisor: CGFloat) -> CGFloat {
        return dividend.truncatingRemainder(dividingBy: divisor)
    }
    
    static func halfRound(_ value: CGFloat) -> CGFloat {
        return round(value * 2) * 0.5
    }
    
    static func halfFloor(_ value: CGFloat) -> CGFloat {
        return floor(value * 2) * 0.5
    }
    
    static func halfCeil(_ value: CGFloat) -> CGFloat {
        return ceil(value * 2) * 0.5
    }
}

// MARK: - Layout Utility

public extension HaruCalendarConstants {
    static func sliceCake(_ cake: CGFloat, count: Int) -> [CGFloat] {
        var pieces = Array<CGFloat>(repeating: 0, count: count)
        var total = cake
        
        for i in 0..<count {
            let remains = count - i
            let piece = halfRound(total / CGFloat(remains))
            total -= piece
            pieces[i] = piece
        }
        
        return pieces
    }
}
