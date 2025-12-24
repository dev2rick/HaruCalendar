//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

public class HaruCalendarView: UIView {
    
    public enum TransitionState: Hashable {
        case idle
        case interactive(attributes: HaruCalendarTransitionAttributes)
        case animating(to: HaruCalendarScope)
    }
    
    public weak var dataSource: HaruCalendarViewDataSource?
    public weak var delegate: HaruCalendarViewDelegate?
    public weak var referenceView: UIScrollView?
    
    public internal(set) var scope: HaruCalendarScope
    public internal(set) var currentPage = Date()
    public internal(set) var calendar: Calendar = .current
    public internal(set) var today = Date()
    public internal(set) var selectedDate = Date()
    public internal(set) var transitionState: TransitionState = .idle
    
    public var minimumDate: Date = .distantPast
    public var maximumDate: Date = .distantFuture
    
    private(set) var numberOfMonths: Int = 0
    private(set) var numberOfWeeks: Int = 0
    
    var collectionViewTopAnchor: NSLayoutConstraint?
    
    private let weekdayView = HaruWeekdayView()
    internal let calendarCollectionView: HaruCalendarCollectionView
    internal let calendarCollectionViewLayout: HaruCalendarCollectionViewLayout
    
    // Caches
    var months: [Int: Date] = [:]
    var monthHeads: [Int: Date] = [:]
    
    var weeks: [Int: Date] = [:]
    var rowCounts: [Date: Int] = [:]
    
    var transitionHeight: CGFloat? = nil {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        recognizer.delegate = self
        recognizer.minimumNumberOfTouches = 1
        recognizer.maximumNumberOfTouches = 2
        return recognizer
    }()
    
    public init(scope: HaruCalendarScope) {
        self.calendarCollectionViewLayout = HaruCalendarCollectionViewLayout()
        self.calendarCollectionView = HaruCalendarCollectionView(
            frame: .zero,
            collectionViewLayout: calendarCollectionViewLayout
        )
        self.scope = scope
        super.init(frame: .zero)
        calendarCollectionViewLayout.calendar = self
        clipsToBounds = true
        setupView()
        setupLayout()
        
        DispatchQueue.main.async { [weak self] in
            self?.reloadCalendar()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        
        calendarCollectionView.delegate = self
        calendarCollectionView.dataSource = self
        calendarCollectionView.internalDelegate = self
        
        weekdayView.setupLabels(with: calendar)
    }
    
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        calendarCollectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    private func setupLayout() {
        weekdayView.translatesAutoresizingMaskIntoConstraints = false
        calendarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(weekdayView)
        addSubview(calendarCollectionView)
        
        let collectionViewTopAnchor = calendarCollectionView.topAnchor.constraint(equalTo: weekdayView.bottomAnchor)
        self.collectionViewTopAnchor = collectionViewTopAnchor
        sendSubviewToBack(calendarCollectionView)
        NSLayoutConstraint.activate([
            weekdayView.topAnchor.constraint(equalTo: topAnchor),
            weekdayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            weekdayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            collectionViewTopAnchor,
            calendarCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            calendarCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            calendarCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    internal func reloadSections() {
        numberOfMonths = calculateNumberOfMonths()
        numberOfWeeks = calculateNumberOfWeeks()
        
        // Clear caches
        months.removeAll()
        monthHeads.removeAll()
        weeks.removeAll()
        rowCounts.removeAll()
    }
    
    private func isPageInRange(_ page: Date) -> Bool {
        page >= minimumDate && page <= maximumDate
    }
    
    private func isDateInRange(_ date: Date) -> Bool {
        calendar.compare(date, to: minimumDate, toGranularity: .day) != .orderedAscending &&
        calendar.compare(date, to: maximumDate, toGranularity: .day) != .orderedDescending
    }
    
    private func selectDate(_ date: Date, scrollToDate: Bool, at monthPosition: HaruCalendarMonthPosition) {
        guard isDateInRange(date) else { return }
        
        // Check if should select
        if let shouldSelect = delegate?.calendar(self, shouldSelect: date, at: monthPosition),
           !shouldSelect {
            return
        }
        
        selectedDate = date
        
        if let section = indexPath(for: currentPage, scope: scope)?.section, scrollToDate {
            calendarCollectionView.scrollToSection(section, animated: true)
        }
        
        delegate?.calendar(self, didSelect: date, at: monthPosition)
    }
}

public extension HaruCalendarView {
    
    func reloadCalendar(for page: Date? = nil) {
        reloadSections()
        calendarCollectionView.reloadData()
        
        let date = page ?? currentPage
        scrollTo(date: date, animated: false)
    }
    
    func scrollTo(date: Date, animated: Bool) {
        guard let section = indexPath(for: date, scope: scope)?.section else {
            return
        }
        
        calendarCollectionView.scrollToSection(section, animated: animated)
    }
    
    func setScope(_ scope: HaruCalendarScope, animated: Bool = true) {
        guard transitionState == .idle, self.scope != scope else { return }
        
        let fromScope = self.scope
        let toScope = scope
        self.scope = scope
        performTransition(
            fromScope: fromScope,
            toScope: toScope,
            animated: animated
        )
    }
    
    func sizeThatFits(_ size: CGSize, scope: HaruCalendarScope) -> CGSize {
        if let rowHeight = dataSource?.heightForRow(self) {
            let numberOfRows: CGFloat = scope == .month ? 6 : 1
            var totalHeight = rowHeight * numberOfRows
            totalHeight += weekdayView.intrinsicContentSize.height
            return CGSize(width: size.width, height: totalHeight)
        } else {
            return size
        }
    }
}

extension HaruCalendarView: UICollectionViewDataSource {
    
    public override var intrinsicContentSize: CGSize {
        let noIntrinsicMetric = UIView.noIntrinsicMetric
        var size = CGSize(width: noIntrinsicMetric, height: noIntrinsicMetric)
        
        if let transitionHeight {
            size.height = transitionHeight
        } else if let rowHeight = dataSource?.heightForRow(self) {
            let numberOfRows: CGFloat = scope == .month ? 6 : 1
            size.height = rowHeight * numberOfRows
            size.height += weekdayView.intrinsicContentSize.height
        }
        return size
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch scope {
        case .month: numberOfMonths
        case .week: numberOfWeeks
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch scope {
        case .month: 42 // 6 rows × 7 days = 42 cells maximum
        case .week: 7
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get cell from dataSource (which should dequeue for reuse)
        guard let date = date(for: indexPath),
              let calendarCell = dataSource?.calendar(self, cellForItemAt: date, at: indexPath) else {
            fatalError("Invalid date or cell for item at indexPath: \(indexPath)")
        }

        let monthPosition = monthPosition(for: indexPath)

        // Configure using protocol methods
        calendarCell.configure(date: date, monthPosition: monthPosition, scope: scope)

        // Set selection state
        let isSelected = date == selectedDate
        calendarCell.setCalendarSelected(isSelected)

        // Sync collection view selection
        if isSelected {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        } else {
            collectionView.deselectItem(at: indexPath, animated: false)
        }

        return calendarCell
    }
}

extension HaruCalendarView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let date = date(for: indexPath) else { return false }
        
        let monthPosition = monthPosition(for: indexPath)
        
        if !isDateInRange(date) {
            return false
        }
        
        return delegate?.calendar(self, shouldSelect: date, at: monthPosition) ?? true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let date = date(for: indexPath) else { return }

        let monthPosition = monthPosition(for: indexPath)
        selectDate(date, scrollToDate: false, at: monthPosition)

        // Update cell selection state using protocol
        if let calendarCell = collectionView.cellForItem(at: indexPath) as? HaruCalendarCell {
            calendarCell.setCalendarSelected(true)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let date = date(for: indexPath) else { return false }
        guard selectedDate != date else { return false }
        let monthPosition = monthPosition(for: indexPath)
        return delegate?.calendar(self, shouldDeselect: date, at: monthPosition) ?? true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let date = date(for: indexPath) else { return }

        // Update cell selection state using protocol
        if let calendarCell = collectionView.cellForItem(at: indexPath) as? (any HaruCalendarCell) {
            calendarCell.setCalendarSelected(false)
            calendarCell.updateAppearance()
        }

        let monthPosition = monthPosition(for: indexPath)
        delegate?.calendar(self, didDeselect: date, at: monthPosition)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let date = date(for: indexPath) else {
            return
        }
        let monthPosition = monthPosition(for: indexPath)
        delegate?.calendar(self, willDisplay: cell, for: date, at: monthPosition)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let section = calendarCollectionView.currentSection
        if let date = page(for: section) {
            currentPage = date
            delegate?.calendarCurrentPageDidChange(self)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let section = calendarCollectionView.currentSection
        if let date = page(for: section) {
            currentPage = date
            delegate?.calendarCurrentPageDidChange(self)
        }
    }
}

extension HaruCalendarView: HaruCalendarCollectionViewInternalDelegate {
    func collectionViewDidFinishLayoutSubviews(_ collectionView: HaruCalendarCollectionView) {
        collectionView.visibleCells
            .compactMap { $0 as? (any HaruCalendarCell) }
            .forEach { $0.updateAppearance() }
    }
}

// MARK: - Custom Cell Support

public extension HaruCalendarView {
    /// Returns the month position for a given index path
    /// Useful when configuring custom cells
    /// - Parameter indexPath: The index path to query
    /// - Returns: The month position (previous, current, next, or notFound)
    func getMonthPosition(for indexPath: IndexPath) -> HaruCalendarMonthPosition {
        return monthPosition(for: indexPath)
    }

    /// Returns whether a date is currently selected
    /// - Parameter date: The date to check
    /// - Returns: True if the date is selected
    func isDateSelected(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
}
