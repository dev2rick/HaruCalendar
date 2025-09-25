//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

public class HaruCalendarCollectionViewLayout: UICollectionViewLayout {
    
    // MARK: - Public Properties
    weak var calendar: HaruCalendarView?
    
    public var sectionInsets: UIEdgeInsets = .zero
    public let scrollDirection: UICollectionView.ScrollDirection = .horizontal
    
    // MARK: - Private Properties
    private var widths: [CGFloat] = []
    private var heights: [CGFloat] = []
    private var lefts: [CGFloat] = []
    private var tops: [CGFloat] = []
    
    private var contentSize: CGSize = .zero
    private var collectionViewSize: CGSize = .zero
    private var numberOfSections: Int = 0
    private var numberOfRows: Int {
        guard let scope = calendar?.scope else { return 0 }
        switch scope {
        case .month: return 6
        case .week: return 1
        }
    }
    
    // Cached layout attributes
    private var itemAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    public override func prepare() {
        super.prepare()
        
        guard let collectionView, let calendar else { return }
        
        let currentSize = collectionView.frame.size
        let currentSections = collectionView.numberOfSections
        
        // Only recalculate if size or section count changed
        guard
            collectionViewSize != currentSize ||
            numberOfSections != currentSections
        else {
            return
        }
        
        // Update cached values
        collectionViewSize = currentSize
        numberOfSections = currentSections
        
        // Clear cached attributes when layout changes
        itemAttributes.removeAll()
        
        // Calculate widths and positions for columns (7 days)
        let contentWidth = collectionViewSize.width - sectionInsets.left - sectionInsets.right
        let itemWidth = contentWidth / 7.0
        
        widths = Array(repeating: itemWidth, count: 7)
        lefts = (0 ..< 7).map { CGFloat($0) * itemWidth + sectionInsets.left }
        
        // Calculate heights and positions for rows (6 rows max)
        let contentHeight = collectionViewSize.height - sectionInsets.top - sectionInsets.bottom
        let itemHeight = contentHeight / CGFloat(numberOfRows)
        
        heights = Array(repeating: itemHeight, count: numberOfRows)
        tops = (0 ..< numberOfRows).map { CGFloat($0) * itemHeight + sectionInsets.top }
        
        // Calculate total content size
        let totalWidth = CGFloat(numberOfSections) * collectionViewSize.width
        contentSize = CGSize(width: totalWidth, height: collectionViewSize.height)
    }
    
    public override var collectionViewContentSize: CGSize {
        return contentSize
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var layoutAttributes: [UICollectionViewLayoutAttributes] = []
        
        // FSCalendar-style horizontal scrolling calculation
        let startSection = Int(rect.minX / collectionViewSize.width)
        let endSection = Int(rect.maxX / collectionViewSize.width)
        
        let startColumn = startSection * 7
        let endColumn = min((endSection + 1) * 7 - 1, numberOfSections * 7 - 1)
        
        for column in startColumn ... endColumn {
            for row in 0 ..< numberOfRows {
                let section = column / 7
                let item = (column % 7) + row * 7
                let indexPath = IndexPath(item: item, section: section)
                
                if let attributes = layoutAttributesForItem(at: indexPath) {
                    layoutAttributes.append(attributes)
                }
            }
        }
        
        return layoutAttributes
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // Check cache first
        if let cachedAttributes = itemAttributes[indexPath] {
            return cachedAttributes
        }
        
        // Calculate on demand (FSCalendar style)
        guard indexPath.section < numberOfSections,
              indexPath.item < 42, // Max items per section (6 rows × 7 days)
              !widths.isEmpty,
              !heights.isEmpty else {
            return nil
        }
        
        let column = indexPath.item % 7
        let row = indexPath.item / 7
        
        guard row < numberOfRows else { return nil }
        
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        // Calculate frame using FSCalendar-style positioning
        let x = lefts[column] + CGFloat(indexPath.section) * collectionViewSize.width
        let y = tops[row]
        let width = widths[column]
        let height = heights[row]
        
        attributes.frame = CGRect(x: x, y: y, width: width, height: height)
        
        // Cache the calculated attributes
        itemAttributes[indexPath] = attributes
        
        return attributes
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds != collectionView?.bounds
    }
}
