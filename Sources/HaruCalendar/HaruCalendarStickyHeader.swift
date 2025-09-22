//
//  HaruCalendarStickyHeader.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - HaruCalendarStickyHeaderDelegate

@objc public protocol HaruCalendarStickyHeaderDelegate: NSObjectProtocol {
    @objc optional func stickyHeader(_ stickyHeader: HaruCalendarStickyHeader, didTapPreviousButton button: UIButton)
    @objc optional func stickyHeader(_ stickyHeader: HaruCalendarStickyHeader, didTapNextButton button: UIButton)
    @objc optional func stickyHeader(_ stickyHeader: HaruCalendarStickyHeader, didTapTitleLabel label: UILabel)
}

// MARK: - HaruCalendarStickyHeader

/// A sticky header view that remains visible at the top of the calendar during scrolling
public class HaruCalendarStickyHeader: UIView {
    
    // MARK: - Properties
    
    /// The calendar instance
    public weak var calendar: HaruCalendar? {
        didSet {
            configureAppearance()
        }
    }
    
    /// The delegate for handling header interactions
    public weak var delegate: HaruCalendarStickyHeaderDelegate?
    
    /// Controls whether navigation buttons are hidden
    public var navigationButtonsHidden: Bool = false {
        didSet {
            previousButton.isHidden = navigationButtonsHidden
            nextButton.isHidden = navigationButtonsHidden
            setNeedsLayout()
        }
    }
    
    /// Controls whether the title is hidden
    public var titleHidden: Bool = false {
        didSet {
            titleLabel.isHidden = titleHidden
            setNeedsLayout()
        }
    }
    
    /// The date formatter used for the title
    public let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    // MARK: - UI Components
    
    /// The title label showing the current month/year
    public let titleLabel: UILabel
    
    /// The previous month navigation button
    public let previousButton: UIButton
    
    /// The next month navigation button
    public let nextButton: UIButton
    
    /// Background view for styling
    public let backgroundView: UIView
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        self.titleLabel = UILabel()
        self.previousButton = UIButton(type: .system)
        self.nextButton = UIButton(type: .system)
        self.backgroundView = UIView()
        
        super.init(frame: frame)
        
        setupSubviews()
        setupConstraints()
        configureComponents()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:) instead.")
        return nil
    }
    
    // MARK: - Setup
    
    private func setupSubviews() {
        addSubview(backgroundView)
        addSubview(titleLabel)
        addSubview(previousButton)
        addSubview(nextButton)
    }
    
    private func setupConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Background view fills the entire header
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Previous button (left side)
            previousButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: 44),
            previousButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Next button (right side)
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title label (center)
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previousButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: nextButton.leadingAnchor, constant: -8)
        ])
    }
    
    private func configureComponents() {
        // Configure title label
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        
        let titleTapGesture = UITapGestureRecognizer(target: self, action: #selector(titleLabelTapped))
        titleLabel.addGestureRecognizer(titleTapGesture)
        titleLabel.isUserInteractionEnabled = true
        
        // Configure previous button
        previousButton.setTitle("‹", for: .normal)
        previousButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        previousButton.tintColor = .systemBlue
        previousButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        
        // Configure next button
        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        nextButton.tintColor = .systemBlue
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        // Configure background
        backgroundView.backgroundColor = UIColor.systemBackground
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 1)
        backgroundView.layer.shadowOpacity = 0.1
        backgroundView.layer.shadowRadius = 2
    }
    
    // MARK: - Actions
    
    @objc private func previousButtonTapped() {
        delegate?.stickyHeader?(self, didTapPreviousButton: previousButton)
        
        // Default behavior: go to previous month
        if let calendar = calendar {
            let currentPage = calendar.currentPage
            if let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentPage) {
                calendar.setCurrentPage(previousMonth, animated: true)
            }
        }
    }
    
    @objc private func nextButtonTapped() {
        delegate?.stickyHeader?(self, didTapNextButton: nextButton)
        
        // Default behavior: go to next month
        if let calendar = calendar {
            let currentPage = calendar.currentPage
            if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentPage) {
                calendar.setCurrentPage(nextMonth, animated: true)
            }
        }
    }
    
    @objc private func titleLabelTapped() {
        delegate?.stickyHeader?(self, didTapTitleLabel: titleLabel)
    }
    
    // MARK: - Configuration
    
    /// Update the header with the current page
    public func updateCurrentPage(_ page: Date) {
        dateFormatter.locale = calendar?.locale ?? Locale.current
        titleLabel.text = dateFormatter.string(from: page)
    }
    
    /// Configure the appearance based on the calendar's settings
    public func configureAppearance() {
        guard let calendar = calendar else { return }
        
        // Update date formatter
        dateFormatter.locale = calendar.locale
        dateFormatter.timeZone = calendar.timeZone
        
        // Update title with current page
        updateCurrentPage(calendar.currentPage)
        
        // Configure colors based on calendar appearance
        let appearance = calendar.appearance
        titleLabel.textColor = appearance.headerTitleColor
        previousButton.tintColor = appearance.headerTitleColor
        nextButton.tintColor = appearance.headerTitleColor
        titleLabel.font = appearance.headerTitleFont
    }
}

// MARK: - Layout

extension HaruCalendarStickyHeader {
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: HaruCalendarConstants.standardHeaderHeight)
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: HaruCalendarConstants.standardHeaderHeight)
    }
}
