//
//  HaruCalendarCollectionView.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - Internal Delegate Protocol

protocol HaruCalendarCollectionViewInternalDelegate: UICollectionViewDelegate {
    func collectionViewDidFinishLayoutSubviews(_ collectionView: HaruCalendarCollectionView)
}

// MARK: - HaruCalendarCollectionView

public class HaruCalendarCollectionView: UICollectionView {
    
    // MARK: - Properties
    
    weak var internalDelegate: HaruCalendarCollectionViewInternalDelegate?
    
    // MARK: - Overridden Properties
    
    /// Always returns false to prevent scrolling to top
    public override var scrollsToTop: Bool {
        get { return false }
        set { super.scrollsToTop = false }
    }
    
    /// Always returns zero to prevent automatic content inset adjustments
    public override var contentInset: UIEdgeInsets {
        get { return .zero }
        set { 
            super.contentInset = .zero
            // Handle top inset adjustment
            if newValue.top > 0 {
                let currentOffset = contentOffset
                contentOffset = CGPoint(
                    x: currentOffset.x,
                    y: currentOffset.y + newValue.top
                )
            }
        }
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    public init(frame: CGRect) {
        super.init(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(frame:collectionViewLayout:) instead.")
        return nil
    }
    
    // MARK: - Setup
    
    private func commonInit() {
        // Disable scroll to top
        scrollsToTop = false
        
        // Set zero content inset
        contentInset = .zero
        
        // Disable prefetching for performance
        if #available(iOS 10.0, *) {
            isPrefetchingEnabled = false
        }
        
        // Disable automatic content inset adjustment
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        
        // Calendar-specific optimizations
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        decelerationRate = UIScrollView.DecelerationRate.fast
        
        // Improve performance
        layer.shouldRasterize = false
        clipsToBounds = true
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Notify internal delegate when layout is finished
        internalDelegate?.collectionViewDidFinishLayoutSubviews(self)
    }
    
    // MARK: - Scroll Behavior
    
    /// Prevents automatic content offset adjustments by UIScrollView internals
    public override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        // Allow controlled content offset changes
        super.setContentOffset(contentOffset, animated: animated)
    }
    
    /// Ensures content inset is always zero
    public override func setContentInset(_ contentInset: UIEdgeInsets) {
        super.setContentInset(.zero)
        
        // Handle legacy top inset adjustment
        if contentInset.top > 0 {
            let currentOffset = self.contentOffset
            self.contentOffset = CGPoint(
                x: currentOffset.x,
                y: currentOffset.y + contentInset.top
            )
        }
    }
    
    // MARK: - Performance Optimizations
    
    public override func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        
        // Optimize cell for calendar use
        cell.layer.shouldRasterize = false
        cell.clipsToBounds = true
        
        return cell
    }
    
    // MARK: - Hit Testing
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        // Allow touches to pass through to calendar if needed
        if hitView == self {
            return nil
        }
        
        return hitView
    }
}

// MARK: - Calendar Integration

extension HaruCalendarCollectionView {
    
    /// Scrolls to specific month or week section with animation
    func scrollToSection(_ section: Int, animated: Bool) {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
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
    var currentSection: Int {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        
        if layout.scrollDirection == .horizontal {
            return max(0, Int(round(contentOffset.x / bounds.width)))
        } else {
            return max(0, Int(round(contentOffset.y / bounds.height)))
        }
    }
    
    /// Reloads data with performance optimizations
    func reloadDataWithOptimizations() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        reloadData()
        CATransaction.commit()
    }
}