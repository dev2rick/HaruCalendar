//
//  HaruCalendarCell.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - HaruCalendarCell

open class HaruCalendarCell: UICollectionViewCell {
    
    // MARK: - Public Properties
    
    /// The day text label of the cell
    public let titleLabel: UILabel
    
    /// The subtitle label of the cell
    public let subtitleLabel: UILabel
    
    /// The shape layer of the cell
    public let shapeLayer: CAShapeLayer
    
    /// The imageView below shape layer of the cell
    public let imageView: UIImageView
    
    /// The collection of event dots of the cell
    public let eventIndicator: HaruCalendarEventIndicator
    
    /// A boolean value indicates that whether the cell is "placeholder". Default is false.
    public var isPlaceholder: Bool = false
    
    // MARK: - Internal Properties
    
    weak var calendar: HaruCalendar?
    weak var appearance: HaruCalendarAppearance?
    
    var subtitle: String?
    var image: UIImage?
    var monthPosition: HaruCalendarMonthPosition = .current
    
    var numberOfEvents: Int = 0
    var dateIsToday: Bool = false
    var isWeekend: Bool = false
    
    // MARK: - Preferred Appearance Properties
    
    var preferredFillDefaultColor: UIColor?
    var preferredFillSelectionColor: UIColor?
    var preferredTitleDefaultColor: UIColor?
    var preferredTitleSelectionColor: UIColor?
    var preferredSubtitleDefaultColor: UIColor?
    var preferredSubtitleSelectionColor: UIColor?
    var preferredBorderDefaultColor: UIColor?
    var preferredBorderSelectionColor: UIColor?
    
    
    var preferredEventDefaultColors: [UIColor]?
    var preferredEventSelectionColors: [UIColor]?
    var preferredBorderRadius: CGFloat = 0
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        // Create subviews
        self.imageView = UIImageView()
        self.shapeLayer = CAShapeLayer()
        self.titleLabel = UILabel()
        self.subtitleLabel = UILabel()
        self.eventIndicator = HaruCalendarEventIndicator()
        
        super.init(frame: frame)
        
        setupSubviews()
        setupConstraints()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:) instead.")
        return nil
    }
    
    // MARK: - Layout
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // Handle subtitle visibility and layout
        if let subtitle = subtitle, !subtitle.isEmpty {
            subtitleLabel.text = subtitle
            if subtitleLabel.isHidden {
                subtitleLabel.isHidden = false
            }
            layoutWithSubtitle()
        } else {
            if !subtitleLabel.isHidden {
                subtitleLabel.isHidden = true
            }
            layoutWithoutSubtitle()
        }
        
        // Layout image
        layoutImageView()
        
        // Layout shape layer
        layoutShapeLayer()
        
        // Layout event indicator
        layoutEventIndicator()
        
        configureAppearance()
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        // Avoid interrupt of navigation transition
        if window != nil {
            CATransaction.setDisableActions(true)
        }
        
        shapeLayer.opacity = 0
        contentView.layer.removeAnimation(forKey: "opacity")
        
        // Reset cell state
        isPlaceholder = false
        subtitle = nil
        image = nil
        numberOfEvents = 0
        dateIsToday = false
        isWeekend = false
        
        // Reset preferred appearance
        preferredFillDefaultColor = nil
        preferredFillSelectionColor = nil
        preferredTitleDefaultColor = nil
        preferredTitleSelectionColor = nil
        preferredSubtitleDefaultColor = nil
        preferredSubtitleSelectionColor = nil
        preferredBorderDefaultColor = nil
        preferredBorderSelectionColor = nil
        
        _preferredTitleOffset = HaruCalendarConstants.pointInfinity
        _preferredSubtitleOffset = HaruCalendarConstants.pointInfinity
        _preferredImageOffset = HaruCalendarConstants.pointInfinity
        _preferredEventOffset = HaruCalendarConstants.pointInfinity
        
        preferredEventDefaultColors = nil
        preferredEventSelectionColors = nil
        preferredBorderRadius = -1
    }
    
    // MARK: - Layout Methods
    
    private func layoutWithSubtitle() {
        let titleHeight = titleLabel.font.lineHeight
        let subtitleHeight = subtitleLabel.font.lineHeight
        let totalHeight = titleHeight + subtitleHeight
        
        let contentHeight = contentView.bounds.height
        let availableHeight = contentHeight * 5.0 / 6.0
        
        titleLabel.frame = CGRect(
            x: preferredTitleOffset.x,
            y: (availableHeight - totalHeight) * 0.5 + preferredTitleOffset.y,
            width: contentView.bounds.width,
            height: titleHeight
        )
        
        subtitleLabel.frame = CGRect(
            x: preferredSubtitleOffset.x,
            y: titleLabel.frame.maxY + preferredSubtitleOffset.y,
            width: contentView.bounds.width,
            height: subtitleHeight
        )
    }
    
    private func layoutWithoutSubtitle() {
        let availableHeight = contentView.bounds.height * 5.0 / 6.0
        
        titleLabel.frame = CGRect(
            x: preferredTitleOffset.x,
            y: preferredTitleOffset.y,
            width: contentView.bounds.width,
            height: HaruCalendarConstants.floor(availableHeight)
        )
    }
    
    private func layoutImageView() {
        imageView.frame = CGRect(
            x: preferredImageOffset.x,
            y: preferredImageOffset.y,
            width: contentView.bounds.width,
            height: contentView.bounds.height
        )
    }
    
    private func layoutShapeLayer() {
        let titleHeight = bounds.height * 5.0 / 6.0
        var diameter = min(titleHeight, bounds.width)
        
        if diameter > HaruCalendarConstants.standardCellDiameter {
            diameter = diameter - (diameter - HaruCalendarConstants.standardCellDiameter) * 0.5
        }
        
        shapeLayer.frame = CGRect(
            x: (bounds.width - diameter) / 2,
            y: (titleHeight - diameter) / 2,
            width: diameter,
            height: diameter
        )
        
        let cornerRadius = diameter * 0.5 * borderRadius
        let path = UIBezierPath(roundedRect: shapeLayer.bounds, cornerRadius: cornerRadius)
        
        if shapeLayer.path != path.cgPath {
            shapeLayer.path = path.cgPath
        }
    }
    
    private func layoutEventIndicator() {
        let eventSize = shapeLayer.frame.height / 6.0
        
        eventIndicator.frame = CGRect(
            x: preferredEventOffset.x,
            y: shapeLayer.frame.maxY + eventSize * 0.17 + preferredEventOffset.y,
            width: bounds.width,
            height: eventSize * 0.83
        )
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        // Configure Image View
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        // Configure Shape Layer
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.borderWidth = 1.0
        shapeLayer.borderColor = UIColor.clear.cgColor
        shapeLayer.opacity = 0
        contentView.layer.insertSublayer(shapeLayer, below: titleLabel.layer)
        
        // Configure Title Label
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: HaruCalendarConstants.standardTitleTextSize)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Configure Subtitle Label
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: HaruCalendarConstants.standardSubtitleTextSize)
        subtitleLabel.isHidden = true
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Configure Event Indicator
        eventIndicator.backgroundColor = .clear
        eventIndicator.isHidden = true
        eventIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eventIndicator)
        
        // Configure clipping
        clipsToBounds = false
        contentView.clipsToBounds = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Image View
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor),
            
            // Title Label
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -2),
            
            // Subtitle Label
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            
            // Event Indicator
            eventIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            eventIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),
            eventIndicator.heightAnchor.constraint(equalToConstant: HaruCalendarConstants.maximumEventDotDiameter)
        ])
    }
    
    // MARK: - Configuration
    
    open func configureAppearance() {
        // Update title color and font
        let titleColor = colorForTitleLabel
        if titleLabel.textColor != titleColor {
            titleLabel.textColor = titleColor
        }
        
        if let titleFont = appearance?.titleFont, titleLabel.font != titleFont {
            titleLabel.font = titleFont
        }
        
        // Update subtitle if present
        if subtitle != nil {
            let subtitleColor = colorForSubtitleLabel
            if subtitleLabel.textColor != subtitleColor {
                subtitleLabel.textColor = subtitleColor
            }
            
            if let subtitleFont = appearance?.subtitleFont, subtitleLabel.font != subtitleFont {
                subtitleLabel.font = subtitleFont
            }
        }
        
        // Update shape layer
        let borderColor = colorForCellBorder
        let fillColor = colorForCellFill
        
        let shouldHideShapeLayer = !isSelected && !dateIsToday && borderColor == nil && fillColor == nil
        
        if shapeLayer.opacity == (shouldHideShapeLayer ? 1 : 0) {
            shapeLayer.opacity = shouldHideShapeLayer ? 0 : 1
        }
        
        if !shouldHideShapeLayer {
            if let cellFillColor = fillColor, shapeLayer.fillColor != cellFillColor.cgColor {
                shapeLayer.fillColor = cellFillColor.cgColor
            }
            
            if let cellBorderColor = borderColor, shapeLayer.strokeColor != cellBorderColor.cgColor {
                shapeLayer.strokeColor = cellBorderColor.cgColor
            }
        }
        
        // Update image
        if imageView.image != image {
            imageView.image = image
            imageView.isHidden = image == nil
        }
        
        // Update event indicator
        if eventIndicator.isHidden == (numberOfEvents > 0) {
            eventIndicator.isHidden = numberOfEvents == 0
        }
        
        eventIndicator.numberOfEvents = numberOfEvents
        eventIndicator.eventColors = colorsForEvents
    }
    
    // MARK: - Color Calculation
    
    private var colorForCellFill: UIColor? {
        if isSelected {
            return preferredFillSelectionColor ?? appearance?.backgroundColors[.selected]
        }
        return preferredFillDefaultColor ?? appearance?.backgroundColors[.normal]
    }
    
    private var colorForTitleLabel: UIColor? {
        if isSelected {
            return preferredTitleSelectionColor ?? appearance?.titleColors[.selected]
        }
        return preferredTitleDefaultColor ?? appearance?.titleColors[.normal]
    }
    
    private var colorForSubtitleLabel: UIColor? {
        if isSelected {
            return preferredSubtitleSelectionColor ?? appearance?.subtitleColors[.selected]
        }
        return preferredSubtitleDefaultColor ?? appearance?.subtitleColors[.normal]
    }
    
    private var colorForCellBorder: UIColor? {
        if isSelected {
            return preferredBorderSelectionColor ?? appearance?.borderSelectionColor
        }
        return preferredBorderDefaultColor ?? appearance?.borderDefaultColor
    }
    
    private var colorsForEvents: [UIColor] {
        if isSelected {
            return preferredEventSelectionColors ?? [appearance?.eventSelectionColor ?? HaruCalendarConstants.standardEventDotColor]
        }
        return preferredEventDefaultColors ?? [appearance?.eventDefaultColor ?? HaruCalendarConstants.standardEventDotColor]
    }
    
    private var borderRadius: CGFloat {
        return preferredBorderRadius >= 0 ? preferredBorderRadius : (appearance?.borderRadius ?? 1.0)
    }
    
    // MARK: - Computed Properties for Offsets
    
    private var preferredTitleOffset: CGPoint {
        get {
            return _preferredTitleOffset == HaruCalendarConstants.pointInfinity ? 
                   (appearance?.titleOffset ?? .zero) : _preferredTitleOffset
        }
        set {
            let shouldUpdate = _preferredTitleOffset != newValue
            _preferredTitleOffset = newValue
            if shouldUpdate {
                setNeedsLayout()
            }
        }
    }
    
    private var preferredSubtitleOffset: CGPoint {
        get {
            return _preferredSubtitleOffset == HaruCalendarConstants.pointInfinity ? 
                   (appearance?.subtitleOffset ?? .zero) : _preferredSubtitleOffset
        }
        set {
            let shouldUpdate = _preferredSubtitleOffset != newValue
            _preferredSubtitleOffset = newValue
            if shouldUpdate {
                setNeedsLayout()
            }
        }
    }
    
    private var preferredImageOffset: CGPoint {
        get {
            return _preferredImageOffset == HaruCalendarConstants.pointInfinity ? 
                   (appearance?.imageOffset ?? .zero) : _preferredImageOffset
        }
        set {
            let shouldUpdate = _preferredImageOffset != newValue
            _preferredImageOffset = newValue
            if shouldUpdate {
                setNeedsLayout()
            }
        }
    }
    
    private var preferredEventOffset: CGPoint {
        get {
            return _preferredEventOffset == HaruCalendarConstants.pointInfinity ? 
                   (appearance?.eventOffset ?? .zero) : _preferredEventOffset
        }
        set {
            let shouldUpdate = _preferredEventOffset != newValue
            _preferredEventOffset = newValue
            if shouldUpdate {
                setNeedsLayout()
            }
        }
    }
    
    // MARK: - Private Offset Storage
    
    private var _preferredTitleOffset: CGPoint = HaruCalendarConstants.pointInfinity
    private var _preferredSubtitleOffset: CGPoint = HaruCalendarConstants.pointInfinity
    private var _preferredImageOffset: CGPoint = HaruCalendarConstants.pointInfinity
    private var _preferredEventOffset: CGPoint = HaruCalendarConstants.pointInfinity
    
    // MARK: - Helpers
    
    func performSelecting() {
        shapeLayer.opacity = 1
        
        // Create bounce animation
        let animationGroup = CAAnimationGroup()
        
        let zoomOut = CABasicAnimation(keyPath: "transform.scale")
        zoomOut.fromValue = 0.3
        zoomOut.toValue = 1.2
        zoomOut.duration = HaruCalendarConstants.defaultBounceAnimationDuration * 3/4
        
        let zoomIn = CABasicAnimation(keyPath: "transform.scale")
        zoomIn.fromValue = 1.2
        zoomIn.toValue = 1.0
        zoomIn.beginTime = HaruCalendarConstants.defaultBounceAnimationDuration * 3/4
        zoomIn.duration = HaruCalendarConstants.defaultBounceAnimationDuration * 1/4
        
        animationGroup.duration = HaruCalendarConstants.defaultBounceAnimationDuration
        animationGroup.animations = [zoomOut, zoomIn]
        
        shapeLayer.add(animationGroup, forKey: "bounce")
        configureAppearance()
    }
}

// MARK: - HaruCalendarEventIndicator

public class HaruCalendarEventIndicator: UIView {
    
    // MARK: - Properties
    
    public var numberOfEvents: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var eventColors: [UIColor] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:) instead.")
        return nil
    }
    
    // MARK: - Drawing
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard numberOfEvents > 0 else { return }
        
        let context = UIGraphicsGetCurrentContext()
        let diameter = HaruCalendarConstants.maximumEventDotDiameter
        let spacing: CGFloat = 2
        
        let totalWidth = CGFloat(numberOfEvents) * diameter + CGFloat(numberOfEvents - 1) * spacing
        let startX = (rect.width - totalWidth) * 0.5
        let y = rect.midY
        
        for i in 0..<numberOfEvents {
            let x = startX + CGFloat(i) * (diameter + spacing)
            let dotRect = CGRect(x: x, y: y - diameter * 0.5, width: diameter, height: diameter)
            
            let color = i < eventColors.count ? eventColors[i] : HaruCalendarConstants.standardEventDotColor
            context?.setFillColor(color.cgColor)
            context?.fillEllipse(in: dotRect)
        }
    }
}

// MARK: - HaruCalendarBlankCell

public class HaruCalendarBlankCell: UICollectionViewCell {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:) instead.")
        return nil
    }
    
    func configureAppearance() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
}
