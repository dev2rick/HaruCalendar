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
    public private(set) var scope: HaruCalendarScope
    public private(set) var currentPage = Date()
    public private(set) var today = Date()
    public private(set) var selectedDate: Date?
    public var minimumDate: Date = .distantPast
    public var maximumDate: Date = .distantFuture
    public var rowHeight: CGFloat = 100
    
    private(set) var numberOfMonths: Int = 0
    private(set) var numberOfWeeks: Int = 0
    
    private let calendarCollectionView: HaruCalendarCollectionView
    private let calendarCollectionViewLayout: HaruCalendarCollectionViewLayout
    
    // Caches
    var months: [Int: Date] = [:]
    var monthHeads: [Int: Date] = [:]
    
    var weeks: [Int: Date] = [:]
    var rowCounts: [Date: Int] = [:]
    
    public init(scope: HaruCalendarScope) {
        self.calendarCollectionViewLayout = HaruCalendarCollectionViewLayout()
        self.calendarCollectionView = HaruCalendarCollectionView(
            frame: .zero,
            collectionViewLayout: calendarCollectionViewLayout
        )
        self.scope = scope
        super.init(frame: .zero)
        
        calendarCollectionViewLayout.calendar = self
        
        setupView()
        setupLayout()
        
        reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        calendarCollectionView.delegate = self
        calendarCollectionView.dataSource = self
        
        calendarCollectionView.register(
            HaruCalendarCollectionViewCell.self,
            forCellWithReuseIdentifier: HaruCalendarCollectionViewCell.identifier
        )
    }
    
    private func setupLayout() {
        calendarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(calendarCollectionView)
        
        NSLayoutConstraint.activate([
            calendarCollectionView.topAnchor.constraint(equalTo: topAnchor),
            calendarCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            calendarCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            calendarCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func reloadSections() {
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
        
        if let section = indexPath(for: currentPage)?.section, scrollToDate {
            calendarCollectionView.scrollToSection(section, animated: true)
        }
        
        delegate?.calendar(self, didSelect: date, at: monthPosition)
    }
}

public extension HaruCalendarView {
    
    func reloadData() {
        reloadSections()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            calendarCollectionView.reloadData()
            
            if let section = indexPath(for: currentPage)?.section {
                
                calendarCollectionView.scrollToSection(section, animated: false)
            }
        }
    }
    
    func setScope(_ scope: HaruCalendarScope) {
        guard self.scope != scope else { return }
        
        self.scope = scope
        
        // 데이터 재로드 (섹션 수, 아이템 수 업데이트)
        reloadSections()
        
        // IntrinsicContentSize 무효화 (높이 변경)
        invalidateIntrinsicContentSize()
        
        // 애니메이션과 함께 높이 변경
        UIView.animate(withDuration: 5) { [weak self] in
            self?.superview?.layoutIfNeeded()
        } completion: { completed in
            if completed {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    calendarCollectionView.reloadData()
                    
                    if let section = indexPath(for: currentPage)?.section {
                        calendarCollectionView.scrollToSection(section, animated: false)
                    }
                }
            }
        }
    }
}

extension HaruCalendarView: UICollectionViewDataSource {
    
    public override var intrinsicContentSize: CGSize {
        let noIntrinsicMetric = UIView.noIntrinsicMetric
        
        if let rowHeight = dataSource?.heightForRow(self) {
            let numberOfRows: CGFloat = scope == .month ? 6 : 1
            let totalHeight = rowHeight * numberOfRows
            
            return CGSize(width: noIntrinsicMetric, height: totalHeight)
        } else {
            return CGSize(width: noIntrinsicMetric, height: noIntrinsicMetric)
        }
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
        if let cell = collectionView.cellForItem(at: indexPath) as? HaruCalendarCollectionViewCell {
            cell.isSelected = true
            cell.performSelecting()
        }
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
        cell?.shapeLayer.opacity = 0
        selectedDate = nil
        let monthPosition = monthPosition(for: indexPath)
        delegate?.calendar(self, didDeselect: date, at: monthPosition)
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
