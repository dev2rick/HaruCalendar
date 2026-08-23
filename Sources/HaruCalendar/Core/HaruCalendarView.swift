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
    /// The selected day, normalized to the start of the day.
    ///
    /// Set it with `select(_:scrollToDate:animated:)`.
    public internal(set) var selectedDate = Calendar.current.startOfDay(for: Date())
    public internal(set) var transitionState: TransitionState = .idle

    /// Set while an animated scroll started by the calendar itself is running,
    /// so that scroll is not reported as a user-driven page change.
    private var isSuppressingPageChange = false
    
    public var minimumDate: Date = .distantPast
    public var maximumDate: Date = .distantFuture
    
    /// Vertical gap between the weekday header and the calendar grid.
    ///
    /// Defaults to 0. The gap is added to `intrinsicContentSize` and is the
    /// resting value of the grid's top constraint, so transitions animate
    /// relative to it.
    public var weekdaySpacing: CGFloat = 0 {
        didSet {
            guard weekdaySpacing != oldValue else { return }
            if transitionState == .idle {
                setCollectionViewOffset(0)
            }
            invalidateIntrinsicContentSize()
        }
    }
    
    private(set) var numberOfMonths: Int = 0
    private(set) var numberOfWeeks: Int = 0
    
    var collectionViewTopAnchor: NSLayoutConstraint?
    
    /// The weekday header displayed above the calendar grid.
    ///
    /// Defaults to `HaruWeekdayView`. Inject a custom one through
    /// `init(scope:weekdayView:)` or replace it later with `setWeekdayView(_:)`.
    public private(set) var weekdayView: any HaruCalendarWeekdayView
    private var weekdayViewConstraints: [NSLayoutConstraint] = []
    public let calendarCollectionView: HaruCalendarCollectionView
    public let calendarCollectionViewLayout: HaruCalendarCollectionViewLayout
    
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
    
    /// Creates a calendar view.
    /// - Parameters:
    ///   - scope: Initial scope (`.month` or `.week`).
    ///   - weekdayView: Weekday header to use. Pass a custom
    ///     `HaruCalendarWeekdayView` to replace the default header.
    public init(scope: HaruCalendarScope, weekdayView: any HaruCalendarWeekdayView = HaruWeekdayView()) {
        self.weekdayView = weekdayView
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
        
        weekdayView.configure(calendar: calendar)
    }
    
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        calendarCollectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    private func setupLayout() {
        calendarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(calendarCollectionView)
        
        NSLayoutConstraint.activate([
            calendarCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            calendarCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            calendarCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        installWeekdayView(topConstant: weekdaySpacing)
    }
    
    /// Adds `weekdayView` to the hierarchy and (re)creates the constraints that
    /// depend on it, including `collectionViewTopAnchor`.
    private func installWeekdayView(topConstant: CGFloat) {
        NSLayoutConstraint.deactivate(weekdayViewConstraints)
        weekdayViewConstraints.removeAll()
        collectionViewTopAnchor?.isActive = false
        
        weekdayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(weekdayView)
        sendSubviewToBack(calendarCollectionView)
        
        let collectionViewTopAnchor = calendarCollectionView.topAnchor.constraint(equalTo: weekdayView.bottomAnchor)
        collectionViewTopAnchor.constant = topConstant
        self.collectionViewTopAnchor = collectionViewTopAnchor
        
        weekdayViewConstraints = [
            weekdayView.topAnchor.constraint(equalTo: topAnchor),
            weekdayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            weekdayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionViewTopAnchor
        ]
        NSLayoutConstraint.activate(weekdayViewConstraints)
    }
    
    /// Replaces the weekday header with a custom one.
    ///
    /// Only valid while no transition is running; calls made during an
    /// interactive or animating transition are ignored.
    /// - Parameter weekdayView: The header to install.
    public func setWeekdayView(_ weekdayView: any HaruCalendarWeekdayView) {
        guard transitionState == .idle, weekdayView !== self.weekdayView else { return }
        
        let topConstant = collectionViewTopAnchor?.constant ?? 0
        self.weekdayView.removeFromSuperview()
        self.weekdayView = weekdayView
        weekdayView.configure(calendar: calendar)
        installWeekdayView(topConstant: topConstant)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
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
        
        selectedDate = calendar.startOfDay(for: date)
        
        if let section = indexPath(for: currentPage, scope: scope)?.section, scrollToDate {
            calendarCollectionView.scrollToSection(section, animated: true)
        }
        
        delegate?.calendar(self, didSelect: date, at: monthPosition)
    }
    
    /// Positions the grid `offset` points away from its resting place, which
    /// is `weekdaySpacing` below the weekday header.
    ///
    /// Transitions pass negative offsets to slide the grid up; `0` is at rest.
    func setCollectionViewOffset(_ offset: CGFloat) {
        collectionViewTopAnchor?.constant = weekdaySpacing + offset
    }
    
    /// Mirrors `selectedDate` into the collection view's selection state and
    /// into the cells that are already on screen.
    ///
    /// Called after `reloadData()` rather than from `cellForItemAt`, which must
    /// not mutate the collection view. Does nothing until the grid has data,
    /// which is also why `select(_:scrollToDate:animated:)` is safe to call
    /// before the first reload: `reloadCalendar()` runs this again afterwards.
    private func syncSelection() {
        let collectionView = calendarCollectionView

        guard let indexPath = indexPath(for: selectedDate, scope: scope),
              indexPath.section < collectionView.numberOfSections,
              indexPath.item < collectionView.numberOfItems(inSection: indexPath.section) else {
            return
        }

        collectionView.indexPathsForSelectedItems?
            .filter { $0 != indexPath }
            .forEach { collectionView.deselectItem(at: $0, animated: false) }
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])

        refreshVisibleSelection()
    }

    /// Pushes `selectedDate` to the visible cells.
    ///
    /// Cells that are dequeued later pick the state up in `cellForItemAt`, but
    /// the ones already on screen are only reachable this way: programmatic
    /// selection does not run `didSelect`/`didDeselect`.
    private func refreshVisibleSelection() {
        let collectionView = calendarCollectionView

        for cell in collectionView.visibleCells {
            guard let calendarCell = cell as? (any HaruCalendarCell),
                  let indexPath = collectionView.indexPath(for: cell),
                  let date = date(for: indexPath) else { continue }

            calendarCell.setCalendarSelected(calendar.isDate(date, inSameDayAs: selectedDate))
        }
    }

    /// Pages the grid to `date` without reporting the resulting page change.
    ///
    /// A programmatic selection already tells the caller where the calendar
    /// went, so echoing it back through `calendarCurrentPageDidChange(_:)`
    /// would feed the caller's own state back to it.
    private func scrollToPage(of date: Date, animated: Bool) {
        guard let section = indexPath(for: date, scope: scope)?.section,
              let page = page(for: section) else { return }

        currentPage = page

        // Before the first reload there is nothing to scroll; `reloadCalendar()`
        // scrolls to `currentPage` once the grid is loaded.
        let collectionView = calendarCollectionView
        guard collectionView.numberOfSections > section,
              collectionView.currentSection != section else { return }

        // A non-animated offset change never calls back, so only the animated
        // path needs suppressing.
        isSuppressingPageChange = animated
        collectionView.scrollToSection(section, animated: animated)
    }
}

public extension HaruCalendarView {

    /// Selects `date` programmatically.
    ///
    /// Unlike a tap, this reports nothing back through the delegate — neither
    /// `didSelect` nor `calendarCurrentPageDidChange`. The caller already knows
    /// which date it asked for, so echoing it back is how selection ends up
    /// fighting the caller's own state.
    ///
    /// Safe to call before the calendar has loaded: the pending reload picks
    /// the selection and the page up.
    /// - Parameters:
    ///   - date: The date to select. Only the day is significant.
    ///   - scrollToDate: Whether to page the grid to the date. Defaults to `true`.
    ///   - animated: Whether that paging is animated. Defaults to `true`.
    func select(_ date: Date, scrollToDate: Bool = true, animated: Bool = true) {
        guard isDateInRange(date) else { return }

        selectedDate = calendar.startOfDay(for: date)

        if scrollToDate {
            scrollToPage(of: selectedDate, animated: animated)
        }

        syncSelection()
    }

    func reloadCalendar(for page: Date? = nil) {
        reloadSections()
        calendarCollectionView.reloadData()
        syncSelection()
        
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
            totalHeight += weekdayView.weekdayHeight + weekdaySpacing
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
            size.height += weekdayView.weekdayHeight + weekdaySpacing
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

        // Set selection state. Do not call selectItem/deselectItem here:
        // mutating the collection view's selection while it is asking for a
        // cell can make UIKit drop cells mid-scroll. Selection is synced in
        // syncSelection() after reloads instead.
        calendarCell.setCalendarSelected(calendar.isDate(date, inSameDayAs: selectedDate))

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
        guard !calendar.isDate(date, inSameDayAs: selectedDate) else { return false }
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
        let wasSuppressed = isSuppressingPageChange
        isSuppressingPageChange = false

        let section = calendarCollectionView.currentSection
        if let date = page(for: section) {
            currentPage = date
            guard !wasSuppressed else { return }
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
