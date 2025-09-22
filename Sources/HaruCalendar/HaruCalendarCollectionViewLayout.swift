//
//  HaruCalendarCollectionViewLayout.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - HaruCalendarCollectionViewLayout

public class HaruCalendarCollectionViewLayout: UICollectionViewLayout {
    
    // MARK: - Properties
    
    weak var calendar: HaruCalendar?
    
    public var sectionInsets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    public var scrollDirection: UICollectionView.ScrollDirection = .horizontal
    
    // MARK: - Private Properties
    
    private var widths: [CGFloat] = []
    private var heights: [CGFloat] = []
    private var lefts: [CGFloat] = []
    private var tops: [CGFloat] = []
    
    private var sectionHeights: [CGFloat] = []
    private var sectionTops: [CGFloat] = []
    private var sectionBottoms: [CGFloat] = []
    private var sectionRowCounts: [Int] = []
    
    private var estimatedItemSize: CGSize = .zero
    private var contentSize: CGSize = .zero
    private var collectionViewSize: CGSize = .zero
    private var headerReferenceSize: CGSize = .zero
    private var numberOfSections: Int = 0
    private var separators: HaruCalendarSeparators = .none
    
    // Cached layout attributes
    private var itemAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var headerAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var separatorAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    // MARK: - Constants
    
    private static let separatorInterRowsKind = "HaruCalendarSeparatorInterRows"
    private static let separatorInterColumnsKind = "HaruCalendarSeparatorInterColumns"
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init() instead.")
        return nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func commonInit() {
        estimatedItemSize = .zero
        scrollDirection = .horizontal
        sectionInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        // Register decoration views
        register(
            HaruCalendarSeparatorDecorationView.self,
            forDecorationViewOfKind: Self.separatorInterRowsKind
        )
        
        // Add observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveNotifications),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveNotifications),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - Layout Preparation
    
    public override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView,
              let calendar = calendar else { return }
        
        let currentSize = collectionView.frame.size
        let currentSections = collectionView.numberOfSections
        let currentSeparators = calendar.appearance.separators
        
        // Check if layout needs to be recalculated
        if collectionViewSize == currentSize &&
           numberOfSections == currentSections &&
           separators == currentSeparators {
            return
        }
        
        // Update cached values
        collectionViewSize = currentSize
        numberOfSections = currentSections
        separators = currentSeparators
        
        // Clear cached attributes
        itemAttributes.removeAll()
        headerAttributes.removeAll()
        separatorAttributes.removeAll()
        
        // Calculate layout
        calculateLayout()
    }
    
    private func calculateLayout() {
        guard let collectionView = collectionView,
              let calendar = calendar else { return }
        
        // Reset arrays
        widths.removeAll()
        heights.removeAll()
        lefts.removeAll()
        tops.removeAll()
        sectionHeights.removeAll()
        sectionTops.removeAll()
        sectionBottoms.removeAll()
        sectionRowCounts.removeAll()
        
        let collectionViewSize = collectionView.bounds.size
        let numberOfSections = collectionView.numberOfSections
        
        // Calculate section metrics
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for section in 0..<numberOfSections {
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            let numberOfRows = calendar.calculator.numberOfRows(in: section)
            
            sectionRowCounts.append(numberOfRows)
            
            if scrollDirection == .horizontal {
                // Horizontal scrolling: each section is a page
                let sectionWidth = collectionViewSize.width
                let sectionHeight = collectionViewSize.height - sectionInsets.top - sectionInsets.bottom
                
                let itemWidth = sectionWidth / 7 // 7 days per week
                let itemHeight = sectionHeight / CGFloat(numberOfRows)
                
                sectionTops.append(sectionInsets.top)
                sectionHeights.append(sectionHeight)
                sectionBottoms.append(sectionInsets.top + sectionHeight)
                
                totalWidth += sectionWidth
                
                // Calculate item positions for this section
                for item in 0..<numberOfItems {
                    let row = item / 7
                    let column = item % 7
                    
                    let indexPath = IndexPath(item: item, section: section)
                    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                    
                    let x = CGFloat(section) * sectionWidth + CGFloat(column) * itemWidth
                    let y = sectionInsets.top + CGFloat(row) * itemHeight
                    
                    attributes.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
                    itemAttributes[indexPath] = attributes
                }
                
            } else {
                // Vertical scrolling: sections stack vertically
                let sectionWidth = collectionViewSize.width - sectionInsets.left - sectionInsets.right
                let itemWidth = sectionWidth / 7
                let itemHeight = calendar.rowHeight > 0 ?
                    calendar.rowHeight : 
                    HaruCalendarConstants.standardRowHeight
                
                let sectionHeight = CGFloat(numberOfRows) * itemHeight
                
                sectionTops.append(totalHeight + sectionInsets.top)
                sectionHeights.append(sectionHeight)
                sectionBottoms.append(totalHeight + sectionInsets.top + sectionHeight)
                
                totalHeight += sectionInsets.top + sectionHeight + sectionInsets.bottom
                
                // Calculate item positions for this section
                for item in 0..<numberOfItems {
                    let row = item / 7
                    let column = item % 7
                    
                    let indexPath = IndexPath(item: item, section: section)
                    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                    
                    let x = sectionInsets.left + CGFloat(column) * itemWidth
                    let y = sectionTops[section] + CGFloat(row) * itemHeight
                    
                    attributes.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
                    itemAttributes[indexPath] = attributes
                }
            }
        }
        
        // Set content size
        if scrollDirection == .horizontal {
            contentSize = CGSize(width: totalWidth, height: collectionViewSize.height)
        } else {
            contentSize = CGSize(width: collectionViewSize.width, height: totalHeight)
        }
        
        // Calculate separator attributes if needed
        calculateSeparatorAttributes()
    }
    
    private func calculateSeparatorAttributes() {
        guard separators.contains(.interRows),
              let collectionView = collectionView else { return }
        
        let numberOfSections = collectionView.numberOfSections
        
        for section in 0..<numberOfSections {
            let numberOfRows = sectionRowCounts[section]
            
            for row in 0..<(numberOfRows - 1) {
                let indexPath = IndexPath(item: row, section: section)
                let attributes = UICollectionViewLayoutAttributes(
                    forDecorationViewOfKind: Self.separatorInterRowsKind,
                    with: indexPath
                )
                
                if scrollDirection == .horizontal {
                    let sectionWidth = collectionView.bounds.width
                    let itemHeight = (collectionView.bounds.height - sectionInsets.top - sectionInsets.bottom) / CGFloat(numberOfRows)
                    
                    let x = CGFloat(section) * sectionWidth
                    let y = sectionInsets.top + CGFloat(row + 1) * itemHeight
                    
                    attributes.frame = CGRect(
                        x: x,
                        y: y,
                        width: sectionWidth,
                        height: HaruCalendarConstants.standardSeparatorThickness
                    )
                } else {
                    let itemHeight = HaruCalendarConstants.standardRowHeight
                    let y = sectionTops[section] + CGFloat(row + 1) * itemHeight
                    
                    attributes.frame = CGRect(
                        x: sectionInsets.left,
                        y: y,
                        width: collectionView.bounds.width - sectionInsets.left - sectionInsets.right,
                        height: HaruCalendarConstants.standardSeparatorThickness
                    )
                }
                
                separatorAttributes[indexPath] = attributes
            }
        }
    }
    
    // MARK: - Layout Attributes
    
    public override var collectionViewContentSize: CGSize {
        return contentSize
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []
        
        // Add item attributes
        for (_, itemAttr) in itemAttributes {
            if itemAttr.frame.intersects(rect) {
                attributes.append(itemAttr)
            }
        }
        
        // Add separator attributes
        for (_, separatorAttr) in separatorAttributes {
            if separatorAttr.frame.intersects(rect) {
                attributes.append(separatorAttr)
            }
        }
        
        return attributes
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemAttributes[indexPath]
    }
    
    public override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == Self.separatorInterRowsKind {
            return separatorAttributes[indexPath]
        }
        return nil
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return !newBounds.size.equalTo(collectionView?.bounds.size ?? .zero)
    }
    
    // MARK: - Notifications
    
    @objc private func didReceiveNotifications(_ notification: Notification) {
        switch notification.name {
        case UIDevice.orientationDidChangeNotification,
             UIApplication.didReceiveMemoryWarningNotification:
            invalidateLayout()
        default:
            break
        }
    }
}

// MARK: - Layout Calculations

private extension HaruCalendarCollectionViewLayout {
    
    func calculateRowOffset(_ row: Int, totalRows: Int) -> CGFloat {
        guard let calendar = calendar else { return 0 }
        
        let totalHeight = collectionView?.bounds.height ?? 0
        let availableHeight = totalHeight - sectionInsets.top - sectionInsets.bottom
        let rowHeight = availableHeight / CGFloat(totalRows)
        
        return sectionInsets.top + CGFloat(row) * rowHeight
    }
}
