//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

public class HaruCalendarView: UIView {
    public var scope: HaruCalendarScope = .month
    public var calendar: Calendar = .current
    public var currentPage: Date = Date()
    public var minimumDate: Date
    public var maximumDate: Date
    
    private(set) var numberOfMonths: Int = 0
    private(set) var numberOfWeeks: Int = 0
    
    private let calendarCollectionView: HaruCalendarCollectionView
    private let calendarCollectionViewLayout: HaruCalendarCollectionViewLayout
    
    // Caches
    var months: [Int: Date] = [:]
    var monthHeads: [Int: Date] = [:]
    
    var weeks: [Int: Date] = [:]
    var rowCounts: [Date: Int] = [:]
    
    override init(frame: CGRect) {
        self.calendarCollectionViewLayout = HaruCalendarCollectionViewLayout()
        self.calendarCollectionView = HaruCalendarCollectionView(
            frame: .zero,
            collectionViewLayout: calendarCollectionViewLayout
        )
        self.minimumDate = Date(timeIntervalSince1970: 0) // 1970-01-01
        self.maximumDate = Date(timeIntervalSince1970: 4102358400) // 2099-12-31
        
        super.init(frame: frame)
        
        numberOfMonths = calculateNumberOfMonths()
        numberOfWeeks = calculateNumberOfWeeks()
        calendarCollectionViewLayout.calendar = self
        
        setupView()
        setupLayout()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            calendarCollectionView.reloadData()
            
            let index = indexPath(for: currentPage)
            calendarCollectionView.scrollToSection(index?.section ?? 0, animated: false)
        }
        
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
}

public extension HaruCalendarView {
    func reloadSections() {
        numberOfMonths = calculateNumberOfMonths()
        numberOfWeeks = calculateNumberOfWeeks()
        
        // Clear caches
        months.removeAll()
        monthHeads.removeAll()
        weeks.removeAll()
        rowCounts.removeAll()
    }
}

extension HaruCalendarView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfMonths
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 42 // 6 rows × 7 days = 42 cells maximum
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HaruCalendarCollectionViewCell.identifier,
            for: indexPath
        ) as! HaruCalendarCollectionViewCell
        
        let monthPosition = monthPosition(for: indexPath)
        let date = date(for: indexPath)!
        cell.calendarView = self
        cell.config(from: date, monthPosition: monthPosition)
        return cell
    }
}
