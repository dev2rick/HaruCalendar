//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

protocol HaruCalendarCollectionViewInternalDelegate: UICollectionViewDelegate {
    func collectionViewDidFinishLayoutSubviews(_ collectionView: HaruCalendarCollectionView)
}

public final class HaruCalendarCollectionView: UICollectionView {
    weak var internalDelegate: HaruCalendarCollectionViewInternalDelegate?
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        isPagingEnabled = true
        
        // Disable scroll to top
        scrollsToTop = false
        
        // Set zero content inset
        contentInset = .zero
        
        // Disable prefetching for performance
        isPrefetchingEnabled = false
        
        // Disable automatic content inset adjustment
        contentInsetAdjustmentBehavior = .never
        
        // Calendar-specific optimizations
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        decelerationRate = UIScrollView.DecelerationRate.fast
        
        // Improve performance
        clipsToBounds = true
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Notify internal delegate when layout is finished
        internalDelegate?.collectionViewDidFinishLayoutSubviews(self)
    }
    
    public override func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        
        cell.clipsToBounds = true
        return cell
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HaruCalendarCollectionView {
    
    /// Scrolls to specific month or week section with animation
    public func scrollToSection(_ section: Int, animated: Bool) {
        
        guard let layout = collectionViewLayout as? HaruCalendarCollectionViewLayout else { return }
        
        var contentOffset: CGPoint
        
        if layout.scrollDirection == .horizontal {
            let sectionWidth = bounds.width
            contentOffset = CGPoint(x: CGFloat(section) * sectionWidth, y: 0)
        } else {
            let sectionHeight = bounds.height
            contentOffset = CGPoint(x: 0, y: CGFloat(section) * sectionHeight)
        }
        
        setContentOffset(contentOffset, animated: animated)
    }
    
    /// Gets the currently visible section
    public var currentSection: Int {
        guard let layout = collectionViewLayout as? HaruCalendarCollectionViewLayout else { return 0 }
        
        if layout.scrollDirection == .horizontal {
            return max(0, Int(round(contentOffset.x / bounds.width)))
        } else {
            return max(0, Int(round(contentOffset.y / bounds.height)))
        }
    }
}
