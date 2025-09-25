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
    
    private var estimatedItemSize: CGSize = .zero
    private var contentSize: CGSize = .zero
    private var collectionViewSize: CGSize = .zero
    private var headerReferenceSize: CGSize = .zero
    private var numberOfSections: Int = 0
    private let numberOfRows: Int = 6
    
    // Cached layout attributes
    private var itemAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var headerAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    public override func prepare() {
        super.prepare()
        guard let collectionView, let calendar else { return }
        
        let currentSize = collectionView.frame.size
        let currentSections = collectionView.numberOfSections
        
        guard
            collectionViewSize != currentSize ||
            numberOfSections != currentSections
        else {
            return
        }
        
        // Update cached values
        collectionViewSize = currentSize
        numberOfSections = currentSections
        
        // Clear cached attributes
        itemAttributes.removeAll()
        headerAttributes.removeAll()
        
        // Calculate layout
        
        // Calculate section metrics
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for section in 0 ..< numberOfSections {
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            
            // Horizontal scrolling: each section is a page
            let sectionWidth = collectionViewSize.width
            let sectionHeight = collectionViewSize.height - sectionInsets.top - sectionInsets.bottom
            
            let itemWidth = sectionWidth / 7 // 7 days per week
            let itemHeight = sectionHeight / CGFloat(numberOfRows)
            
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
        }
        
        contentSize = CGSize(width: totalWidth, height: collectionViewSize.height)
    }
    
    public override var collectionViewContentSize: CGSize {
        return contentSize
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return itemAttributes.values.filter { $0.frame.intersects(rect) }
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemAttributes[indexPath]
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds != collectionView?.bounds
    }
}
