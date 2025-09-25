//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

public class HaruCalendarView: UIView {
    
    public var calendar: Calendar = .current
    public private(set) var scope: HaruCalendarScope
    public private(set) var currentPage = Date()
    public private(set) var today = Date()
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
        self.scope = scope
        reloadData()
    }
}

extension HaruCalendarView: UICollectionViewDelegate, UICollectionViewDataSource {
    
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
        let date = date(for: indexPath)!
        cell.calendarView = self
        cell.config(from: date, monthPosition: monthPosition, scope: scope)
        return cell
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let section = calendarCollectionView.currentSection
        if let date = page(for: section) {
            currentPage = date
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let section = calendarCollectionView.currentSection
        if let date = page(for: section) {
            currentPage = date
        }
    }
}
