//
//  HaruCalendarWeekdayView.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - HaruCalendarWeekdayView

public class HaruCalendarWeekdayView: UIView {
    
    // MARK: - Properties
    
    /// An array of UILabel objects displaying the weekday symbols
    public let weekdayLabels: [UILabel]
    
    private let contentView: UIView
    weak var calendar: HaruCalendar? {
        didSet {
            configureAppearance()
        }
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        // Create content view
        self.contentView = UIView()
        
        // Create 7 weekday labels
        var labels: [UILabel] = []
        for _ in 0..<7 {
            let label = UILabel()
            label.textAlignment = .center
            labels.append(label)
        }
        
        labels.forEach(contentView.addSubview)
        
        self.weekdayLabels = labels
        
        super.init(frame: frame)
        
        // Add content view
        addSubview(contentView)
        
        // Add weekday labels to content view
        
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:) instead.")
        return nil
    }
    
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = bounds
        
        // Calculate widths for each weekday label
        let count = weekdayLabels.count
        let contentWidth = contentView.bounds.width
        let widths = HaruCalendarConstants.sliceCake(contentWidth, count: count)
        
        // Handle RTL layout
        let isRTL = isRightToLeftLayout()
        var x: CGFloat = 0
        
        for i in 0..<count {
            let width = widths[i]
            let labelIndex = isRTL ? count - 1 - i : i
            let label = weekdayLabels[labelIndex]
            
            label.frame = CGRect(
                x: x,
                y: 0,
                width: width,
                height: contentView.bounds.height
            )
            
            x += width
        }
    }
    
    // MARK: - Configuration
    
    public func configureAppearance() {
        guard let calendar = calendar else { return }
        
        // Determine which weekday symbols to use
        let useVeryShort = calendar.appearance.caseOptions.contains(.weekdayUsesSingleUpperCase)
        let weekdaySymbols = useVeryShort ? 
            Calendar.current.veryShortStandaloneWeekdaySymbols :
            Calendar.current.shortStandaloneWeekdaySymbols
        
        let useDefaultCase = calendar.appearance.caseOptions.contains(.weekdayUsesDefaultCase)
        
        // Configure each weekday label
        for (i, label) in weekdayLabels.enumerated() {
            let index = (i + calendar.firstWeekday - 1) % 7
            
            label.font = calendar.appearance.weekdayFont
            label.textColor = calendar.appearance.weekdayTextColor
            
            let text = weekdaySymbols[index]
            label.text = useDefaultCase ? text : text.uppercased()
        }
    }
    
    // MARK: - Helpers
    
    private func isRightToLeftLayout() -> Bool {
        let direction = UIView.userInterfaceLayoutDirection(
            for: calendar?.semanticContentAttribute ?? .unspecified
        )
        return direction == .rightToLeft
    }
}

// MARK: - Calendar Integration

extension HaruCalendarWeekdayView {
    
    /// Updates weekday symbols based on calendar's first weekday
    func updateWeekdaySymbols() {
        configureAppearance()
    }
    
    /// Updates appearance based on calendar's current appearance settings
    func updateAppearance() {
        configureAppearance()
        setNeedsLayout()
    }
}
