//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

public class HaruCalendarView: UIView {
    
    public weak var dataSource: HaruCalendarViewDataSource?
    public weak var delegate: HaruCalendarViewDelegate?
    
    public var calendar: Calendar = .current
    public internal(set) var scope: HaruCalendarScope
    public internal(set) var currentPage = Date()
    public private(set) var today = Date()
    public private(set) var selectedDate: Date?
    public var minimumDate: Date = .distantPast
    public var maximumDate: Date = .distantFuture
    public var rowHeight: CGFloat = 100
    
    private(set) var numberOfMonths: Int = 0
    private(set) var numberOfWeeks: Int = 0
    
    var collectionViewTopAnchor: NSLayoutConstraint?
    private var coordinator: HaruCalendarTransitionCoordinator!
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
    
    public init(scope: HaruCalendarScope) {
        self.calendarCollectionViewLayout = HaruCalendarCollectionViewLayout()
        self.calendarCollectionView = HaruCalendarCollectionView(
            frame: .zero,
            collectionViewLayout: calendarCollectionViewLayout
        )
        self.scope = scope
        super.init(frame: .zero)
        coordinator = HaruCalendarTransitionCoordinator(calendar: self)
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
        
        calendarCollectionView.register(
            HaruCalendarCollectionViewCell.self,
            forCellWithReuseIdentifier: HaruCalendarCollectionViewCell.identifier
        )
    }
    
    private func setupLayout() {
        calendarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(calendarCollectionView)
        
        let collectionViewTopAnchor = calendarCollectionView.topAnchor.constraint(equalTo: topAnchor)
        self.collectionViewTopAnchor = collectionViewTopAnchor
        
        NSLayoutConstraint.activate([
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
    
    func setReferenceScrollView(_ scrollView: UIScrollView) {
        coordinator.setReferenceScrollView(scrollView)
    }
    
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
    
    func setScope(_ scope: HaruCalendarScope) {
        guard coordinator.state == .idle, self.scope != scope else { return }
        
        let fromScope = self.scope
        let toScope = scope
        self.scope = scope
        
        coordinator.performTransition(
            fromScope: fromScope,
            toScope: toScope,
            animated: true
        )
    }
    
    func sizeThatFits(_ size: CGSize, scope: HaruCalendarScope) -> CGSize {
        if let rowHeight = dataSource?.heightForRow(self) {
            let numberOfRows: CGFloat = scope == .month ? 6 : 1
            let totalHeight = rowHeight * numberOfRows
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
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HaruCalendarCollectionViewCell.identifier,
            for: indexPath
        ) as! HaruCalendarCollectionViewCell
        
        let monthPosition = monthPosition(for: indexPath)
        
        cell.calendarView = self
        
        if let date = date(for: indexPath) {
            
            cell.isSelected = date == selectedDate
            if cell.isSelected {
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            } else {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
            
            cell.config(from: date, monthPosition: monthPosition, scope: scope)
        }
        
        return cell
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
        
        // Perform selection animation
        let cell = collectionView.cellForItem(at: indexPath) as? HaruCalendarCollectionViewCell
        cell?.isSelected = true
        cell?.performSelecting()
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let date = date(for: indexPath) else { return false }
        
        let monthPosition = monthPosition(for: indexPath)
        return delegate?.calendar(self, shouldDeselect: date, at: monthPosition) ?? true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let date = date(for: indexPath) else { return }
        let cell = collectionView.cellForItem(at: indexPath) as? HaruCalendarCollectionViewCell
        cell?.isSelected = false
        selectedDate = nil
        let monthPosition = monthPosition(for: indexPath)
        delegate?.calendar(self, didDeselect: date, at: monthPosition)
        cell?.configAppearance()
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard
            let calendarCell = cell as? HaruCalendarCollectionViewCell,
            let date = date(for: indexPath) else {
            return
        }
        let monthPosition = monthPosition(for: indexPath)
        delegate?.calendar(self, willDisplay: calendarCell, for: date, at: monthPosition)
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
            .map { $0 as? HaruCalendarCollectionViewCell }
            .forEach { $0?.configAppearance() }
    }
}
