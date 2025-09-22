//
//  HaruCalendarSeparatorDecorationView.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - HaruCalendarSeparatorDecorationView

/// A decoration view that renders separators between calendar rows and columns
public class HaruCalendarSeparatorDecorationView: UICollectionReusableView {
    
    // MARK: - Properties
    
    /// The calendar that owns this separator view
    public weak var calendar: HaruCalendar?
    
    /// The separator color
    public var separatorColor: UIColor = HaruCalendarConstants.defaultSeparatorColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The orientation of the separator
    public var orientation: HaruCalendarSeparatorOrientation = .horizontal {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:) instead.")
        return nil
    }
    
    private func commonInit() {
        backgroundColor = UIColor.clear
        isOpaque = false
        
        // Configure appearance
        separatorColor = HaruCalendarConstants.defaultSeparatorColor
    }
    
    // MARK: - Reuse
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        calendar = nil
        separatorColor = HaruCalendarConstants.defaultSeparatorColor
        orientation = .horizontal
    }
    
    // MARK: - Drawing
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(separatorColor.cgColor)
        context.setLineWidth(1.0 / UIScreen.main.scale) // Use pixel-perfect line width
        
        switch orientation {
        case .horizontal:
            drawHorizontalSeparator(in: rect, context: context)
        case .vertical:
            drawVerticalSeparator(in: rect, context: context)
        }
    }
    
    private func drawHorizontalSeparator(in rect: CGRect, context: CGContext) {
        let y = rect.midY
        
        context.move(to: CGPoint(x: rect.minX, y: y))
        context.addLine(to: CGPoint(x: rect.maxX, y: y))
        context.strokePath()
    }
    
    private func drawVerticalSeparator(in rect: CGRect, context: CGContext) {
        let x = rect.midX
        
        context.move(to: CGPoint(x: x, y: rect.minY))
        context.addLine(to: CGPoint(x: x, y: rect.maxY))
        context.strokePath()
    }
    
    // MARK: - Configuration
    
    /// Configure the separator view with the calendar's appearance
    public func configureAppearance() {
        guard let calendar = calendar else { return }
        
        separatorColor = HaruCalendarConstants.defaultSeparatorColor
        setNeedsDisplay()
    }
}

// MARK: - HaruCalendarSeparatorOrientation

/// Defines the orientation of separator lines
@objc public enum HaruCalendarSeparatorOrientation: Int {
    case horizontal = 0
    case vertical = 1
}
