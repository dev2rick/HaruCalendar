//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 11/4/25.
//

import UIKit

extension HaruCalendarView: UIGestureRecognizerDelegate {
    
    public func setReferenceScrollView(_ scrollView: UIScrollView) {
        guard scrollView.superview == superview else {
            fatalError("Reference scrollView must share the same superview as the calendar view.")
        }
        scrollView.superview?.addGestureRecognizer(panGestureRecognizer)
        scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        referenceView = scrollView
    }
    
    @objc
    func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let state = gestureRecognizer.state
        switch state {
        case .began: scopeTransitionDidBegin(gestureRecognizer)
        case .changed: scopeTransitionDidUpdate(gestureRecognizer)
        case .ended, .cancelled, .failed: scopeTransitionDidEnd(gestureRecognizer)
        default: break
        }
    }
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        guard transitionState == .idle else { return false }
        guard let referenceView else { return true }
        
        let shouldBegin = referenceView.contentOffset.y <= -referenceView.contentInset.top
        if shouldBegin {
            let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
            switch scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            }
        }
        return shouldBegin
    }
    
    func scopeTransitionDidBegin(_ panGesture: UIPanGestureRecognizer) {
        guard transitionState == .idle else { return }
        let velocity = panGesture.velocity(in: panGesture.view)
        
        if scope == .month && velocity.y >= 0 {
            return
        }
        if scope == .week && velocity.y <= 0 {
            return
        }
        
        let sourceScope: HaruCalendarScope = scope
        let targetScope: HaruCalendarScope = scope == .month ? .week : .month
        
        let attributes = createTransitionAttributesTargetingScope(sourceScope: sourceScope, targetScope: targetScope)
        transitionState = .interactive(attributes: attributes)
        if targetScope == .month {
            prepareWeekToMonthTransition(from: attributes)
        }
    }
    
    func scopeTransitionDidUpdate(_ panGesture: UIPanGestureRecognizer) {
        guard case .interactive(let attributes) = transitionState else { return }
        var translation = abs(panGesture.translation(in: panGesture.view).y)
        
        let maxTranslation = abs(attributes.sourceBounds.height - attributes.targetBounds.height)
        
        translation = min(translation, maxTranslation)
        translation = max(0, translation)
        
        performPathAnimationWithProgress(progress: translation / maxTranslation)
    }
    
    func performPathAnimationWithProgress(progress: CGFloat) {
        guard case .interactive(let attributes) = transitionState else { return }
        let sourceHeight = attributes.sourceBounds.height
        let targetHeight = attributes.targetBounds.height
        let currentHeight = sourceHeight - (sourceHeight - targetHeight) * progress
        let currentBounds = CGRect(x: 0, y: 0, width: attributes.targetBounds.width, height: currentHeight)
        
        let offset = calculateOffsetForProgress(attributes: attributes, progress: progress)
        collectionViewTopAnchor?.constant = offset
        transitionHeight = currentHeight
    }
    
    func scopeTransitionDidEnd(_ panGesture: UIPanGestureRecognizer) {
        guard case .interactive(let attributes) = transitionState else { return }
        transitionHeight = nil
        performTransition(attributes: attributes, toProgress: 1, animated: true)
    }
}
