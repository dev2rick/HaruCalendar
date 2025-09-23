//
//  HaruCalendarHeaderView.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - HaruCalendarHeaderView

public class HaruCalendarHeaderView: UIView {
    
    // MARK: - Properties
    
    weak var collectionView: HaruCalendarCollectionView?
    
    weak var calendar: HaruCalendar? {
        didSet {
            configureAppearance()
        }
    }
    
    public var scrollDirection: UICollectionView.ScrollDirection = .horizontal {
        didSet {
            if scrollDirection != oldValue {
                headerLayout.scrollDirection = scrollDirection
                setNeedsLayout()
            }
        }
    }
    
    public var scrollEnabled: Bool = true {
        didSet {
            if scrollEnabled != oldValue {
                headerCollectionView.visibleCells.forEach { cell in
                    cell.setNeedsLayout()
                }
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let headerCollectionView: UICollectionView
    private let headerLayout: HaruCalendarHeaderLayout
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        return formatter
    }()
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        // Create header layout
        self.headerLayout = HaruCalendarHeaderLayout()
        
        // Create collection view
        self.headerCollectionView = UICollectionView(frame: .zero, collectionViewLayout: headerLayout)
        
        super.init(frame: frame)
        
        setupCollectionView()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:) instead.")
        return nil
    }
    
    deinit {
        headerCollectionView.dataSource = nil
        headerCollectionView.delegate = nil
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        headerLayout.scrollDirection = scrollDirection
        
        headerCollectionView.isScrollEnabled = false
        headerCollectionView.isUserInteractionEnabled = false
        headerCollectionView.backgroundColor = .clear
        headerCollectionView.dataSource = self
        headerCollectionView.delegate = self
        headerCollectionView.showsHorizontalScrollIndicator = false
        headerCollectionView.showsVerticalScrollIndicator = false
        
        headerCollectionView.register(
            HaruCalendarHeaderCell.self,
            forCellWithReuseIdentifier: HaruCalendarHeaderCell.reuseIdentifier
        )
        
        headerCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(headerCollectionView)
        NSLayoutConstraint.activate([
            headerCollectionView.topAnchor.constraint(equalTo: topAnchor),
            headerCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            headerCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    public func setScrollOffset(_ scrollOffset: CGFloat) {
        setScrollOffset(scrollOffset, animated: false)
    }
    
    public func setScrollOffset(_ scrollOffset: CGFloat, animated: Bool) {
        scrollToOffset(scrollOffset, animated: animated)
    }
    
    public func reloadData() {
        headerCollectionView.reloadData()
    }
    
    public func configureAppearance() {
        headerCollectionView.visibleCells.forEach { cell in
            if let headerCell = cell as? HaruCalendarHeaderCell,
               let indexPath = headerCollectionView.indexPath(for: cell) {
                configureCell(headerCell, at: indexPath)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func scrollToOffset(_ scrollOffset: CGFloat, animated: Bool) {
        if scrollDirection == .horizontal {
            let step = headerCollectionView.bounds.width * 0.5
            let contentOffset = CGPoint(x: (scrollOffset + 0.5) * step, y: 0)
            headerCollectionView.setContentOffset(contentOffset, animated: animated)
        } else {
            let step = headerCollectionView.bounds.height
            let contentOffset = CGPoint(x: 0, y: scrollOffset * step)
            headerCollectionView.setContentOffset(contentOffset, animated: animated)
        }
    }
    
    private func configureCell(_ cell: HaruCalendarHeaderCell, at indexPath: IndexPath) {
        guard let calendar = calendar else { return }
        let appearance = calendar.appearance
        
        // Configure cell appearance
        cell.titleLabel.font = appearance.headerTitleFont
        cell.titleLabel.textColor = appearance.headerTitleColor
        cell.titleLabel.textAlignment = appearance.headerTitleAlignment
        
        // Configure date formatter
        dateFormatter.dateFormat = appearance.headerDateFormat
        
        // Generate text for cell
        var text: String?
        
        switch calendar.scope {
        case .month:
            if scrollDirection == .horizontal {
                // Handle padding cells (first and last)
                let totalItems = headerCollectionView.numberOfItems(inSection: 0)
                if indexPath.item == 0 || indexPath.item == totalItems - 1 {
                    text = nil
                } else {
                    if let date = calendar.gregorian.date(
                        byAdding: .month,
                        value: indexPath.item - 1,
                        to: calendar.minimumDate
                    ) {
                        text = dateFormatter.string(from: date)
                    }
                }
            } else {
                if let date = calendar.gregorian.date(
                    byAdding: .month,
                    value: indexPath.item,
                    to: calendar.minimumDate
                ) {
                    text = dateFormatter.string(from: date)
                }
            }
            
        case .week:
            let totalItems = headerCollectionView.numberOfItems(inSection: 0)
            if indexPath.item == 0 || indexPath.item == totalItems - 1 {
                text = nil
            } else {
                if let middleDay = calendar.gregorian.dateInterval(of: .weekOfYear, for: calendar.minimumDate)?.start,
                   let date = calendar.gregorian.date(
                    byAdding: .weekOfYear,
                    value: indexPath.item - 1,
                    to: middleDay
                   ) {
                    text = dateFormatter.string(from: date)
                }
            }
        }
        
        // Apply case options
        if let text = text {
            if appearance.caseOptions.contains(.headerUsesUpperCase) {
                cell.titleLabel.text = text.uppercased()
            } else if appearance.caseOptions.contains(.headerUsesCapitalized) {
                cell.titleLabel.text = text.capitalized
            } else {
                cell.titleLabel.text = text
            }
        } else {
            cell.titleLabel.text = nil
        }
        
        cell.setNeedsLayout()
    }
}

// MARK: - UICollectionViewDataSource

extension HaruCalendarHeaderView: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let calendar = calendar,
              let mainCollectionView = self.collectionView else {
            return 0
        }
        
        let numberOfSections = mainCollectionView.numberOfSections
        
        if scrollDirection == .vertical {
            return numberOfSections
        }
        
        // Horizontal scroll needs 2 extra padding items
        return numberOfSections + 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HaruCalendarHeaderCell.reuseIdentifier,
            for: indexPath
        ) as! HaruCalendarHeaderCell
        
        cell.header = self
        
        configureCell(cell, at: indexPath)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension HaruCalendarHeaderView: UICollectionViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        headerCollectionView.visibleCells.forEach { cell in
            cell.setNeedsLayout()
        }
    }
}

// MARK: - HaruCalendarHeaderCell

public class HaruCalendarHeaderCell: UICollectionViewCell {
    
    static let reuseIdentifier = "HaruCalendarHeaderCell"
    
    // MARK: - Properties
    
    public let titleLabel: UILabel
    weak var header: HaruCalendarHeaderView?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        self.titleLabel = UILabel()
        
        super.init(frame: frame)
        
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:) instead.")
        return nil
    }
    
    // MARK: - Layout
    
    public override var bounds: CGRect {
        didSet {
            titleLabel.frame = bounds
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let header = header,
              let calendar = header.calendar else {
            titleLabel.frame = contentView.bounds
            return
        }
        let appearance = calendar.appearance
        // Apply header title offset
        let offset = appearance.headerTitleOffset
        titleLabel.frame = contentView.bounds.offsetBy(dx: offset.x, dy: offset.y)
        
        // Calculate alpha based on position for horizontal scroll
        if header.scrollDirection == .horizontal {
            let position = contentView.convert(
                CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY),
                to: header
            ).x
            let center = header.bounds.midX
            
            if header.scrollEnabled {
                let distance = abs(center - position) / bounds.width
                let minAlpha = appearance.headerMinimumDissolvedAlpha
                contentView.alpha = 1.0 - (1.0 - minAlpha) * distance
            } else {
                let isVisible = position > header.bounds.width * 0.25 && position < header.bounds.width * 0.75
                contentView.alpha = isVisible ? 1.0 : 0.0
            }
        } else {
            contentView.alpha = 1.0
        }
    }
}

// MARK: - HaruCalendarHeaderLayout

public class HaruCalendarHeaderLayout: UICollectionViewFlowLayout {
    
    public override init() {
        super.init()
        
        scrollDirection = .horizontal
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        sectionInset = .zero
        itemSize = CGSize(width: 1, height: 1)
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init() instead.")
        return nil
    }
    
    public override func prepare() {
        super.prepare()
        
        guard let collectionView else { return }
        
        let width: CGFloat = ((scrollDirection == .horizontal) ? 0.5 : 1.0) * collectionView.bounds.width

        itemSize = CGSize(
            width: width,
            height: collectionView.bounds.height
        )
    }
    
    public override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return true
    }
}
