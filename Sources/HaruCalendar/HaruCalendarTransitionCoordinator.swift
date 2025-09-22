//
//  HaruCalendarTransitionCoordinator.swift
//  HaruCalendar
//
//  Created by Claude on 2025-09-20.
//  Copyright © 2025 HaruCalendar. All rights reserved.
//

import UIKit

// MARK: - Transition State

public enum HaruCalendarTransitionState {
    case idle
    case changing
    case finishing
}

// MARK: - Transition Attributes

public class HaruCalendarTransitionAttributes: NSObject {
    
    // MARK: - Properties
    
    public var sourceBounds: CGRect = .zero
    public var targetBounds: CGRect = .zero
    public var sourcePage: Date?
    public var targetPage: Date?
    public var focusedRow: Int = 0
    public var focusedDate: Date?
    public var targetScope: HaruCalendarScope = .month
    
    // MARK: - Methods
    
    public func revert() {
        // Swap source and target
        let tempBounds = sourceBounds
        sourceBounds = targetBounds
        targetBounds = tempBounds
        
        let tempPage = sourcePage
        sourcePage = targetPage
        targetPage = tempPage
        
        // Toggle target scope
        targetScope = (targetScope == .month) ? .week : .month
    }
}

// MARK: - HaruCalendarTransitionCoordinator

public class HaruCalendarTransitionCoordinator: NSObject {
    
    // MARK: - Properties
    
    public var state: HaruCalendarTransitionState = .idle
    public var cachedMonthSize: CGSize = .zero
    
    public var representingScope: HaruCalendarScope {
        return calendar?.scope ?? .month
    }
    
    // MARK: - Private Properties
    
    weak var calendar: HaruCalendar?
    private var transitionAttributes: HaruCalendarTransitionAttributes?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    // Animation properties
    private var animator: UIViewPropertyAnimator?
    private var displayLink: CADisplayLink?
    
    // MARK: - Initialization
    
    override public init() {
        super.init()
        setupGestureRecognizer()
    }
    
    public required init?(coder: NSCoder) {
        assertionFailure("Interface Builder is not supported. Use init(calendar:) instead.")
        return nil
    }
    
    deinit {
        displayLink?.invalidate()
        animator?.stopAnimation(true)
    }
    
    // MARK: - Setup
    
    private func setupGestureRecognizer() {
        guard let calendar = calendar else { return }
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleScopeGesture(_:)))
        panGestureRecognizer?.delegate = self
        calendar.addGestureRecognizer(panGestureRecognizer!)
    }
    
    // MARK: - Scope Transition
    
    public func performScopeTransition(from fromScope: HaruCalendarScope, to toScope: HaruCalendarScope, animated: Bool) {
        guard let calendar = calendar,
              fromScope != toScope else { return }
        
        state = .changing
        
        let attributes = HaruCalendarTransitionAttributes()
        attributes.targetScope = toScope
        attributes.sourcePage = calendar.currentPage
        attributes.targetPage = calendar.currentPage
        attributes.sourceBounds = calendar.bounds
        attributes.targetBounds = boundingRect(for: toScope, page: calendar.currentPage)
        
        if let selectedDate = calendar.selectedDate {
            attributes.focusedDate = selectedDate
            attributes.focusedRow = calculateFocusedRow(for: selectedDate, in: toScope)
        }
        
        transitionAttributes = attributes
        
        if animated {
            performAnimatedTransition(attributes: attributes)
        } else {
            performInstantTransition(attributes: attributes)
        }
    }
    
    public func performBoundingRectTransition(from fromMonth: Date, to toMonth: Date, duration: CGFloat) {
        guard let calendar = calendar else { return }
        
        let fromBounds = boundingRect(for: calendar.scope, page: fromMonth)
        let toBounds = boundingRect(for: calendar.scope, page: toMonth)
        
        let attributes = HaruCalendarTransitionAttributes()
        attributes.sourceBounds = fromBounds
        attributes.targetBounds = toBounds
        attributes.sourcePage = fromMonth
        attributes.targetPage = toMonth
        attributes.targetScope = calendar.scope
        
        performBoundingRectAnimation(attributes: attributes, duration: TimeInterval(duration))
    }
    
    public func boundingRect(for scope: HaruCalendarScope, page: Date) -> CGRect {
        guard let calendar = calendar else { return .zero }
        
        let headerHeight = calendar.headerHeight
        let weekdayHeight = calendar.weekdayHeight
        
        switch scope {
        case .month:
            let numberOfRows = calendar.calculator.numberOfRows(in: page)
            let rowHeight = HaruCalendarConstants.standardRowHeight
            let contentHeight = CGFloat(numberOfRows) * rowHeight
            
            return CGRect(
                x: 0,
                y: 0,
                width: calendar.bounds.width,
                height: headerHeight + weekdayHeight + contentHeight
            )
            
        case .week:
            let rowHeight = HaruCalendarConstants.standardRowHeight
            
            return CGRect(
                x: 0,
                y: 0,
                width: calendar.bounds.width,
                height: headerHeight + weekdayHeight + rowHeight
            )
        }
    }
    
    // MARK: - Animation Methods
    
    private func performAnimatedTransition(attributes: HaruCalendarTransitionAttributes) {
        guard let calendar = calendar else { return }
        
        let duration = HaruCalendarConstants.defaultBounceAnimationDuration * 2
        
        // Notify delegate about bounds change
        calendar.delegate?.calendar?(calendar, boundingRectWillChange: attributes.targetBounds, animated: true)
        
        animator = UIViewPropertyAnimator(duration: TimeInterval(duration), dampingRatio: 0.8) {
            calendar.scope = attributes.targetScope
            calendar.frame = attributes.targetBounds
            calendar.setNeedsLayout()
            calendar.layoutIfNeeded()
        }
        
        animator?.addCompletion { [weak self] _ in
            self?.state = .idle
            self?.transitionAttributes = nil
        }
        
        animator?.startAnimation()
    }
    
    private func performInstantTransition(attributes: HaruCalendarTransitionAttributes) {
        guard let calendar = calendar else { return }
        
        // Notify delegate about bounds change
        calendar.delegate?.calendar?(calendar, boundingRectWillChange: attributes.targetBounds, animated: false)
        
        calendar.scope = attributes.targetScope
        calendar.frame = attributes.targetBounds
        calendar.setNeedsLayout()
        
        state = .idle
        transitionAttributes = nil
    }
    
    private func performBoundingRectAnimation(attributes: HaruCalendarTransitionAttributes, duration: TimeInterval) {
        guard let calendar = calendar else { return }
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
            calendar.frame = attributes.targetBounds
            calendar.setNeedsLayout()
            calendar.layoutIfNeeded()
        })
    }
    
    // MARK: - Gesture Handling
    
    @objc public func handleScopeGesture(_ sender: UIPanGestureRecognizer) {
        guard let calendar = calendar,
              state == .idle || state == .changing else { return }
        
        let translation = sender.translation(in: calendar)
        let velocity = sender.velocity(in: calendar)
        
        switch sender.state {
        case .began:
            startInteractiveTransition(translation: translation)
            
        case .changed:
            updateInteractiveTransition(translation: translation)
            
        case .ended, .cancelled:
            finishInteractiveTransition(velocity: velocity)
            
        default:
            break
        }
    }
    
    private func startInteractiveTransition(translation: CGPoint) {
        guard let calendar = calendar,
              state == .idle else { return }
        
        state = .changing
        
        let currentScope = calendar.scope
        let targetScope: HaruCalendarScope = (currentScope == .month) ? .week : .month
        
        let attributes = HaruCalendarTransitionAttributes()
        attributes.targetScope = targetScope
        attributes.sourcePage = calendar.currentPage
        attributes.targetPage = calendar.currentPage
        attributes.sourceBounds = calendar.bounds
        attributes.targetBounds = boundingRect(for: targetScope, page: calendar.currentPage)
        
        if let selectedDate = calendar.selectedDate {
            attributes.focusedDate = selectedDate
            attributes.focusedRow = calculateFocusedRow(for: selectedDate, in: targetScope)
        }
        
        transitionAttributes = attributes
    }
    
    private func updateInteractiveTransition(translation: CGPoint) {
        guard let attributes = transitionAttributes else { return }
        
        let progress = abs(translation.y) / 100.0 // Adjust sensitivity
        let clampedProgress = max(0, min(1, progress))
        
        // Interpolate between source and target bounds
        let currentBounds = interpolateRect(
            from: attributes.sourceBounds,
            to: attributes.targetBounds,
            progress: clampedProgress
        )
        
        calendar?.frame = currentBounds
    }
    
    private func finishInteractiveTransition(velocity: CGPoint) {
        guard let attributes = transitionAttributes else { return }
        
        state = .finishing
        
        let shouldComplete = abs(velocity.y) > 500 || 
                           (calendar?.frame.height ?? 0) != attributes.sourceBounds.height
        
        if shouldComplete {
            performAnimatedTransition(attributes: attributes)
        } else {
            // Revert to original state
            attributes.revert()
            performAnimatedTransition(attributes: attributes)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateFocusedRow(for date: Date, in scope: HaruCalendarScope) -> Int {
        guard let calendar = calendar else { return 0 }
        
        if scope == .week {
            return 0
        }
        
        // Calculate which row the date falls in for month scope
        guard let indexPath = calendar.calculator.indexPath(for: date) else { return 0 }
        return indexPath.item / 7
    }
    
    private func interpolateRect(from fromRect: CGRect, to toRect: CGRect, progress: CGFloat) -> CGRect {
        return CGRect(
            x: fromRect.origin.x + (toRect.origin.x - fromRect.origin.x) * progress,
            y: fromRect.origin.y + (toRect.origin.y - fromRect.origin.y) * progress,
            width: fromRect.width + (toRect.width - fromRect.width) * progress,
            height: fromRect.height + (toRect.height - fromRect.height) * progress
        )
    }
}

// MARK: - UIGestureRecognizerDelegate

extension HaruCalendarTransitionCoordinator: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
              let calendar = calendar else { return false }
        
        let translation = panGesture.translation(in: calendar)
        
        // Only handle vertical pan gestures
        return abs(translation.y) > abs(translation.x)
    }
}
