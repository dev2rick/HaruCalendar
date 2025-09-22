//
//  HaruCalendar.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - HaruCalendar

/// HaruCalendar is a superior calendar control with high performance, high customizability and very simple usage.
public class HaruCalendar: UIView {
    
    // MARK: - Public Properties
    
    /// The timezone of the calendar. Current timezone by default.
    public var timeZone: TimeZone = TimeZone.current {
        didSet {
            gregorian.timeZone = timeZone
            invalidateDateTools()
        }
    }
    
    /// The object that acts as the delegate of the calendar.
    public weak var delegate: HaruCalendarDelegate?
    
    /// The object that acts as the data source of the calendar.
    public weak var dataSource: HaruCalendarDataSource?
    
    /// A special mark will be put on 'today' of the calendar.
    public var today: Date? {
        didSet {
            if today != oldValue {
                configureAppearance()
            }
        }
    }
    
    /// The current page of calendar
    public var currentPage: Date = Date() {
        didSet {
            if currentPage != oldValue {
                scrollToPage(for: currentPage, animated: false)
            }
        }
    }
    
    /// The locale of month and weekday symbols.
    public var locale: Locale = Locale.current {
        didSet {
            gregorian.locale = locale
            invalidateDateTools()
        }
    }
    
    /// The scroll direction of HaruCalendar.
    public var scrollDirection: UICollectionView.ScrollDirection = .horizontal {
        didSet {
            if scrollDirection != oldValue {
                collectionViewLayout.scrollDirection = scrollDirection
                headerView.scrollDirection = scrollDirection
            }
        }
    }
    
    /// The scope of calendar
    public var scope: HaruCalendarScope = .month {
        didSet {
            if scope != oldValue {
                setScope(scope, animated: false)
            }
        }
    }
    
    /// The placeholder type of HaruCalendar.
    public var placeholderType: HaruCalendarPlaceholderType = .fillSixRows {
        didSet {
            if placeholderType != oldValue {
                reloadData()
            }
        }
    }
    
    /// The index of the first weekday of the calendar.
    public var firstWeekday: Int = 1 {
        didSet {
            if firstWeekday != oldValue {
                gregorian.firstWeekday = firstWeekday
                weekdayView.updateWeekdaySymbols()
                reloadData()
            }
        }
    }
    
    /// The height of month header of the calendar.
    public var headerHeight: CGFloat = HaruCalendarConstants.standardHeaderHeight {
        didSet {
            if headerHeight != oldValue {
                setNeedsLayout()
            }
        }
    }
    
    /// The height of weekday header of the calendar.
    public var weekdayHeight: CGFloat = HaruCalendarConstants.standardWeekdayHeight {
        didSet {
            if weekdayHeight != oldValue {
                setNeedsLayout()
            }
        }
    }
    
    /// A Boolean value that determines whether users can select a date.
    public var allowsSelection: Bool = true
    
    /// A Boolean value that determines whether users can select more than one date.
    public var allowsMultipleSelection: Bool = false {
        didSet {
            if !allowsMultipleSelection && selectedDates.count > 1 {
                // Keep only the first selected date
                let firstDate = selectedDates.first
                selectedDates.removeAll()
                if let date = firstDate {
                    selectedDates.append(date)
                }
                reloadData()
            }
        }
    }
    
    /// A Boolean value that determines whether paging is enabled for the calendar.
    public var pagingEnabled: Bool = true {
        didSet {
            collectionView.isPagingEnabled = pagingEnabled
        }
    }
    
    /// A Boolean value that determines whether scrolling is enabled for the calendar.
    public var scrollEnabled: Bool = true {
        didSet {
            collectionView.isScrollEnabled = scrollEnabled
        }
    }
    
    /// The row height of the calendar if paging enabled is NO.
    public var rowHeight: CGFloat = HaruCalendarConstants.standardRowHeight {
        didSet {
            if rowHeight != oldValue {
                reloadData()
            }
        }
    }
    
    /// The calendar appearance used to control the global fonts, colors, etc.
    public var appearance: HaruCalendarAppearance
    
    /// A date object representing the minimum day enable, visible and selectable.
    public var minimumDate: Date = Date.distantPast {
        didSet {
            if minimumDate != oldValue {
                calculator.reloadSections()
                reloadData()
            }
        }
    }
    
    /// A date object representing the maximum day enable, visible and selectable.
    public var maximumDate: Date = Date.distantFuture {
        didSet {
            if maximumDate != oldValue {
                calculator.reloadSections()
                reloadData()
            }
        }
    }
    
    /// A date object identifying the section of the selected date.
    public var selectedDate: Date? {
        return selectedDates.first
    }
    
    /// The dates representing the selected dates.
    public private(set) var selectedDates: [Date] = []
    
    // MARK: - Internal Properties
    
    internal var gregorian: Calendar = Calendar.current
    internal let formatter: DateFormatter = DateFormatter()
    internal let calculator: HaruCalendarCalculator
    internal let transitionCoordinator: HaruCalendarTransitionCoordinator
    
    // UI Components
    private let contentView: UIView
    private let daysContainer: UIView
    internal let collectionView: HaruCalendarCollectionView
    internal let collectionViewLayout: HaruCalendarCollectionViewLayout
    internal let headerView: HaruCalendarHeaderView
    internal let weekdayView: HaruCalendarWeekdayView
    
    // State management
    private var needsAdjustingViewFrame: Bool = false
    private var needsRequestingBoundingDates: Bool = false
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        // Initialize appearance first
        self.appearance = HaruCalendarAppearance()
        
        // Initialize UI components
        self.contentView = UIView()
        self.daysContainer = UIView()
        self.collectionViewLayout = HaruCalendarCollectionViewLayout()
        self.collectionView = HaruCalendarCollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        self.headerView = HaruCalendarHeaderView()
        self.weekdayView = HaruCalendarWeekdayView()
        
        self.calculator = HaruCalendarCalculator()
        self.transitionCoordinator = HaruCalendarTransitionCoordinator()
        
        // Initialize delegation helper
        
        super.init(frame: frame)
        calculator.calendar = self
        transitionCoordinator.calendar = self
        
        // Set up relationships
        setupComponents()
        setupConstraints()
        configureDefaultSettings()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:) instead.")
        return nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupComponents() {
        // Set up appearance relationship
        appearance.calendar = self
        
        // Set up calculator relationship
        calculator.calendar = self
        
        // Set up collection view
        collectionViewLayout.calendar = self
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.internalDelegate = self
        
        // Register cells
        collectionView.register(
            HaruCalendarCell.self,
            forCellWithReuseIdentifier: HaruCalendarConstants.defaultCellReuseIdentifier
        )
        
        // Set up header and weekday views
        headerView.calendar = self
        headerView.collectionView = collectionView
        
        weekdayView.calendar = self
        
        // Add subviews
        addSubview(contentView)
        contentView.addSubview(headerView)
        contentView.addSubview(weekdayView)
        contentView.addSubview(daysContainer)
        daysContainer.addSubview(collectionView)
        
        // Set up observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    private func setupConstraints() {
        // Disable autoresizing masks
        contentView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        weekdayView.translatesAutoresizingMaskIntoConstraints = false
        daysContainer.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Content view fills the entire calendar
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Header view
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight),
            
            // Weekday view
            weekdayView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            weekdayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            weekdayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            weekdayView.heightAnchor.constraint(equalToConstant: weekdayHeight),
            
            // Days container
            daysContainer.topAnchor.constraint(equalTo: weekdayView.bottomAnchor),
            daysContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            daysContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            daysContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Collection view fills days container
            collectionView.topAnchor.constraint(equalTo: daysContainer.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: daysContainer.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: daysContainer.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: daysContainer.bottomAnchor)
        ])
    }
    
    private func configureDefaultSettings() {
        // Set default today
        today = Date()
        
        // Set default current page
        currentPage = Date()
        
        // Configure collection view
        collectionView.isPagingEnabled = pagingEnabled
        collectionView.isScrollEnabled = scrollEnabled
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        // Set up date range
        let calendar = Calendar.current
        minimumDate = calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date.distantPast
        maximumDate = calendar.date(byAdding: .year, value: 10, to: Date()) ?? Date.distantFuture
        
        // Initial setup
        invalidateDateTools()
        reloadData()
    }
    
    // MARK: - Public Methods
    
    /// Reload the dates and appearance of the calendar.
    public func reloadData() {
        calculator.reloadSections()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.headerView.reloadData()
            self.configureAppearance()
        }
    }
    
    /// Change the scope of the calendar.
    public func setScope(_ scope: HaruCalendarScope, animated: Bool) {
        guard self.scope != scope else { return }
        
        let fromScope = self.scope
        self.scope = scope
        
        transitionCoordinator.performScopeTransition(from: fromScope, to: scope, animated: animated)
    }
    
    /// Selects a given date in the calendar.
    public func select(_ date: Date?) {
        select(date, scrollToDate: true)
    }
    
    /// Selects a given date in the calendar, optionally scrolling the date to visible area.
    public func select(_ date: Date?, scrollToDate: Bool) {
        guard let date = date else { return }
        selectDate(date, scrollToDate: scrollToDate, at: .current)
    }
    
    /// Deselects a given date of the calendar.
    public func deselect(_ date: Date) {
        guard selectedDates.contains(date) else { return }
        
        if let index = selectedDates.firstIndex(of: date) {
            selectedDates.remove(at: index)
        }
        
        configureAppearance()
        delegate?.calendar(self, didDeselect: date, at: .current)
    }
    
    /// Changes the current page of the calendar.
    public func setCurrentPage(_ currentPage: Date, animated: Bool) {
        guard isPageInRange(currentPage) else { return }
        
        self.currentPage = currentPage
        scrollToPage(for: currentPage, animated: animated)
    }
    
    /// Register a class for use in creating new calendar cells.
    public func register(_ cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    /// Returns a reusable calendar cell object located by its identifier.
    public func dequeueReusableCell(withIdentifier identifier: String, for date: Date, at position: HaruCalendarMonthPosition) -> HaruCalendarCell {
        guard let indexPath = calculator.indexPath(for: date, at: position) else {
            return HaruCalendarCell()
        }
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! HaruCalendarCell
    }
    
    /// Returns the calendar cell for the specified date.
    public func cell(for date: Date, at position: HaruCalendarMonthPosition) -> HaruCalendarCell? {
        guard let indexPath = calculator.indexPath(for: date, at: position) else { return nil }
        return collectionView.cellForItem(at: indexPath) as? HaruCalendarCell
    }
    
    /// Returns the date of the specified cell.
    public func date(for cell: HaruCalendarCell) -> Date? {
        guard let indexPath = collectionView.indexPath(for: cell) else { return nil }
        return calculator.date(for: indexPath)
    }
    
    /// Returns the month position of the specified cell.
    public func monthPosition(for cell: HaruCalendarCell) -> HaruCalendarMonthPosition {
        guard let indexPath = collectionView.indexPath(for: cell) else { return .notFound }
        return calculator.monthPosition(for: indexPath)
    }
    
    /// Returns an array of visible cells currently displayed by the calendar.
    public func visibleCells() -> [HaruCalendarCell] {
        return collectionView.visibleCells.compactMap { $0 as? HaruCalendarCell }
    }
    
    /// Returns the frame for a non-placeholder cell relative to the super view of the calendar.
    public func frameForDate(_ date: Date) -> CGRect {
        guard let indexPath = calculator.indexPath(for: date),
              let layoutAttributes = collectionViewLayout.layoutAttributesForItem(at: indexPath) else {
            return .zero
        }
        return convert(layoutAttributes.frame, from: collectionView)
    }
    
    // MARK: - Internal Methods
    
    internal func configureAppearance() {
        headerView.configureAppearance()
        weekdayView.configureAppearance()
        collectionView.visibleCells.forEach { cell in
            if let calendarCell = cell as? HaruCalendarCell {
                calendarCell.configureAppearance()
            }
        }
    }
    
    internal func invalidateDateTools() {
        formatter.calendar = gregorian
        formatter.timeZone = timeZone
        formatter.locale = locale
    }
    
    @objc private func orientationDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.setNeedsLayout()
        }
    }
}

// MARK: - Layout

extension HaruCalendar {
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if needsAdjustingViewFrame {
            needsAdjustingViewFrame = false
            setNeedsLayout()
        }
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size, scope: scope)
    }
    
    private func sizeThatFits(_ size: CGSize, scope: HaruCalendarScope) -> CGSize {
        let headerHeight = self.headerHeight
        let weekdayHeight = self.weekdayHeight
        
        switch scope {
        case .month:
            let numberOfRows = 6 // Maximum rows for month view
            let rowHeight = HaruCalendarConstants.standardRowHeight
            let contentHeight = CGFloat(numberOfRows) * rowHeight
            return CGSize(width: size.width, height: headerHeight + weekdayHeight + contentHeight)
            
        case .week:
            let rowHeight = HaruCalendarConstants.standardRowHeight
            return CGSize(width: size.width, height: headerHeight + weekdayHeight + rowHeight)
        }
    }
}

// MARK: - Private Methods

private extension HaruCalendar {
    
    func scrollToPage(for date: Date, animated: Bool) {
        guard let section = calculator.indexPath(for: date)?.section else { return }
        collectionView.scrollToSection(section, animated: animated)
        headerView.setScrollOffset(CGFloat(section), animated: animated)
    }
    
    func selectDate(_ date: Date, scrollToDate: Bool, at monthPosition: HaruCalendarMonthPosition) {
        guard allowsSelection,
              isDateInRange(date) else { return }
        
        // Check if should select
        if let shouldSelect = delegate?.calendar(self, shouldSelect: date, at: monthPosition),
           !shouldSelect {
            return
        }
        
        // Handle multiple selection
        if !allowsMultipleSelection {
            selectedDates.removeAll()
        }
        
        if !selectedDates.contains(date) {
            selectedDates.append(date)
        }
        
        if scrollToDate {
            scrollToPage(for: date, animated: true)
        }
        
        configureAppearance()
        delegate?.calendar(self, didSelect: date, at: monthPosition)
    }
    
    func isPageInRange(_ page: Date) -> Bool {
        return page >= minimumDate && page <= maximumDate
    }
    
    func isDateInRange(_ date: Date) -> Bool {
        return gregorian.compare(date, to: minimumDate, toGranularity: .day) != .orderedAscending &&
               gregorian.compare(date, to: maximumDate, toGranularity: .day) != .orderedDescending
    }
}

// MARK: - UICollectionViewDataSource

extension HaruCalendar: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return calculator.numberOfSections
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 42 // 6 rows × 7 days = 42 cells maximum
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let date = calculator.date(for: indexPath) else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: HaruCalendarConstants.blankCellReuseIdentifier, for: indexPath)
        }
        
        let monthPosition = calculator.monthPosition(for: indexPath)
        
        // Ask data source for custom cell
        if let customCell = dataSource?.calendar(self, cellFor: date, at: monthPosition) {
            return customCell
        }
        
        // Use default cell
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HaruCalendarConstants.defaultCellReuseIdentifier,
            for: indexPath
        ) as! HaruCalendarCell
        
        configureCell(cell, for: date, at: indexPath)
        
        return cell
    }
    
    private func configureCell(_ cell: HaruCalendarCell, for date: Date, at indexPath: IndexPath) {
        let monthPosition = calculator.monthPosition(for: indexPath)
        
        // Set basic properties
        cell.calendar = self
        cell.appearance = appearance
        cell.monthPosition = monthPosition
        cell.dateIsToday = gregorian.isDate(date, inSameDayAs: today ?? Date())
        cell.isWeekend = gregorian.isDateInWeekend(date)
        cell.isPlaceholder = monthPosition != .current
        cell.isSelected = selectedDates.contains(date)
        
        // Set title
        cell.titleLabel.text = gregorian.component(.day, from: date).description
        
        // Set subtitle from data source
        cell.subtitle = dataSource?.calendar(self, subtitleFor: date)
        
        // Set image from data source
        cell.image = dataSource?.calendar(self, imageFor: date)
        
        // Set number of events
        cell.numberOfEvents = dataSource?.calendar(self, numberOfEventsFor: date) ?? 0
        
        // Configure appearance
        cell.configureAppearance()
    }
}

// MARK: - UICollectionViewDelegate

extension HaruCalendar: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard allowsSelection,
              let date = calculator.date(for: indexPath) else { return false }
        
        let monthPosition = calculator.monthPosition(for: indexPath)
        
        if !isDateInRange(date) {
            return false
        }
        
        return delegate?.calendar(self, shouldSelect: date, at: monthPosition) ?? true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let date = calculator.date(for: indexPath) else { return }
        
        let monthPosition = calculator.monthPosition(for: indexPath)
        selectDate(date, scrollToDate: false, at: monthPosition)
        
        // Perform selection animation
        if let cell = collectionView.cellForItem(at: indexPath) as? HaruCalendarCell {
            cell.performSelecting()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard allowsMultipleSelection,
              let date = calculator.date(for: indexPath) else { return false }
        
        let monthPosition = calculator.monthPosition(for: indexPath)
        return delegate?.calendar(self, shouldDeselect: date, at: monthPosition) ?? true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard allowsMultipleSelection,
              let date = calculator.date(for: indexPath) else { return }
        
        let monthPosition = calculator.monthPosition(for: indexPath)
        deselect(date)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let calendarCell = cell as? HaruCalendarCell,
              let date = calculator.date(for: indexPath) else { return }
        
        let monthPosition = calculator.monthPosition(for: indexPath)
        delegate?.calendar(self, willDisplay: calendarCell, for: date, at: monthPosition)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentSection = collectionView.currentSection
        
        if let date = calculator.page(for: currentSection) {
            currentPage = date
            delegate?.calendarCurrentPageDidChange(self)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let currentSection = collectionView.currentSection
        
        if let date = calculator.page(for: currentSection) {
            currentPage = date
            delegate?.calendarCurrentPageDidChange(self)
        }
    }
}

// MARK: - HaruCalendarCollectionViewInternalDelegate

extension HaruCalendar: HaruCalendarCollectionViewInternalDelegate {
    
    func collectionViewDidFinishLayoutSubviews(_ collectionView: HaruCalendarCollectionView) {
        headerView.setScrollOffset(CGFloat(collectionView.currentSection), animated: false)
    }
}
