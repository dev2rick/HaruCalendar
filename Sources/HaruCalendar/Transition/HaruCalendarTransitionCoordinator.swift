//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/26/25.
//

import UIKit

enum FSCalendarTransitionState {
    case idle, changing
}

@MainActor
final class HaruCalendarTransitionCoordinator: NSObject {
    var state: FSCalendarTransitionState = .idle
    var cachedMonthSize: CGSize?
    var representingScope: HaruCalendarScope?
    var attributes: HaruCalendarTransitionAttributes?
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        recognizer.delegate = self
        recognizer.minimumNumberOfTouches = 1
        recognizer.maximumNumberOfTouches = 2
        return recognizer
    }()
    
    let calendar: HaruCalendarView
    
    init(calendar: HaruCalendarView) {
        self.calendar = calendar
    }
    
    public func performTransition(fromScope: HaruCalendarScope, toScope: HaruCalendarScope, animated: Bool) {
        state = .changing
        let attributes = createTransitionAttributesTargetingScope(sourceScope: fromScope,targetScope: toScope)
        if toScope == .month {
            prepareWeekToMonthTransition(from: attributes)
        }
        
        performTransition(attributes: attributes, toProgress: 1, animated: animated)
    }
}

extension HaruCalendarTransitionCoordinator: UIGestureRecognizerDelegate {
    
    func setReferenceScrollView(_ scrollView: UIScrollView) {
        guard scrollView.superview == calendar.superview else {
            fatalError("ScrollView must be a same subview of the calendar view")
        }
        scrollView.superview?.addGestureRecognizer(panGestureRecognizer)
        scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
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
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        guard state == .idle else { return false }
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
        
        var shouldStart: Bool
        if calendar.scope == .week {
            shouldStart = velocity.y >= 0
        } else {
            shouldStart = velocity.y <= 0
        }
        
        if !shouldStart { return false }
        shouldStart = abs(velocity.x) < abs(velocity.y)
        if shouldStart {
            calendar.calendarCollectionView.panGestureRecognizer.isEnabled = false
            calendar.calendarCollectionView.panGestureRecognizer.isEnabled = true
        }
        return shouldStart
    }
    
    func scopeTransitionDidBegin(_ panGesture: UIPanGestureRecognizer) {
        guard state == .idle else { return }
        let velocity = panGesture.velocity(in: panGesture.view)
        
        if calendar.scope == .month && velocity.y >= 0 {
            return
        }
        if calendar.scope == .week && velocity.y <= 0 {
            return
        }
        state = .changing
        
        let target: HaruCalendarScope = calendar.scope == .month ? .week : .month
        calendar.scope = target
        attributes = createTransitionAttributesTargetingScope(sourceScope: calendar.scope, targetScope: target)
        if target == .month, let attributes {
            prepareWeekToMonthTransition(from: attributes)
        }
    }
    
    func scopeTransitionDidUpdate(_ panGesture: UIPanGestureRecognizer) {
        
        guard let attributes, state == .changing else { return }
        var translation = abs(panGesture.translation(in: panGesture.view).y)
        
        let maxTranslation = abs(attributes.sourceBounds.height - attributes.targetBounds.height)
        
        translation = min(translation, maxTranslation)
        translation = max(0, translation)
        
        performPathAnimationWithProgress(progress: translation / maxTranslation)
    }
    
    func scopeTransitionDidEnd(_ panGesture: UIPanGestureRecognizer) {
        guard let attributes, state == .changing else { return }
        calendar.transitionHeight = nil
        performTransition(attributes: attributes, toProgress: 1, animated: true)
    }
}

extension HaruCalendarTransitionCoordinator {
    
    func performTransition(attributes: HaruCalendarTransitionAttributes, toProgress: CGFloat, animated: Bool) {
        let offset = calculateOffsetForProgress(attributes: attributes, progress: toProgress)
        calendar.collectionViewTopAnchor?.constant = offset
        calendar.invalidateIntrinsicContentSize()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
            self?.calendar.superview?.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.performTransitionCompletion(from: attributes)
        }
    }
    
    func calculateOffsetForProgress(attributes: HaruCalendarTransitionAttributes, progress: CGFloat) -> CGFloat {
        guard
            let focusedDate = attributes.focusedDate,
            let indexPath = calendar.indexPath(for: focusedDate, scope: .month),
            let frame = calendar.calendarCollectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame else {
            return 0
        }
        
        let ratio = attributes.targetScope == .week ? progress : (1 - progress)
        let offset = (-frame.origin.y + calendar.calendarCollectionViewLayout.sectionInsets.top) * ratio
        return offset
    }
    
    func performPathAnimationWithProgress(progress: CGFloat) {
        guard let attributes else { return }
        let sourceHeight = attributes.sourceBounds.height
        let targetHeight = attributes.targetBounds.height
        let currentHeight = sourceHeight - (sourceHeight - targetHeight) * progress
        let currentBounds = CGRect(x: 0, y: 0, width: attributes.targetBounds.width, height: currentHeight)
        
        let offset = calculateOffsetForProgress(attributes: attributes, progress: progress)
        calendar.collectionViewTopAnchor?.constant = offset
        calendar.transitionHeight = currentHeight
    }
}

extension HaruCalendarTransitionCoordinator {
    func createTransitionAttributesTargetingScope(sourceScope: HaruCalendarScope, targetScope: HaruCalendarScope) -> HaruCalendarTransitionAttributes {
        // get focusedDate
        
        var candidates: [Date] = []
        if let selectedDate = calendar.selectedDate {
            candidates.append(selectedDate)
        }
        
        candidates.append(contentsOf: [calendar.today, calendar.currentPage])
        let scope = targetScope == .week ? sourceScope : targetScope
        
        let focusedDate = candidates.first {
            let indexPath = calendar.indexPath(for: $0, scope: scope)
            let currentSection = calendar.indexPath(for: calendar.currentPage, scope: scope)?.section
            return indexPath?.section == currentSection
        }
        // get focusedRow
        let focusedRow: Int
        if let focusedDate, let indexPath = calendar.indexPath(for: focusedDate, scope: .month) {
            focusedRow = calendar.coordinate(for: indexPath).row
        } else {
            focusedRow = 0
        }
        
        // get targetPage
        let targetPage: Date?
        if let focusedDate {
            if targetScope == .month {
                targetPage = calendar.calendar.firstDayOfMonth(for: focusedDate)
            } else {
                targetPage = calendar.calendar.middleDayOfWeek(focusedDate)
            }
        } else {
            targetPage = nil
        }
        
        let targetBounds = boundingRectForScope(targetScope)
        
        return .init(
            sourceBounds: calendar.bounds,
            targetBounds: targetBounds,
            sourcePage: calendar.currentPage,
            targetPage: targetPage,
            focusedRow: focusedRow,
            focusedDate: focusedDate,
            targetScope: targetScope
        )
    }
    
    func boundingRectForScope(_ scope: HaruCalendarScope) -> CGRect {
        let contentSize: CGSize
        if let cachedMonthSize, scope == .month {
            contentSize = cachedMonthSize
        } else {
            contentSize = calendar.sizeThatFits(calendar.frame.size, scope: scope)
        }
        return CGRect(origin: .zero, size: contentSize)
    }
  
    func performTransitionCompletion(from attributes: HaruCalendarTransitionAttributes) {
        calendar.collectionViewTopAnchor?.constant = 0
        calendar.superview?.layoutIfNeeded()
        
        if attributes.targetScope == .week {
            calendar.reloadCalendar(for: attributes.targetPage)
        }
        state = .idle
    }
    
    func prepareWeekToMonthTransition(from attributes: HaruCalendarTransitionAttributes) {
        
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        calendar.reloadCalendar(for: attributes.targetPage)
        calendar.layoutIfNeeded()
        
        CATransaction.setDisableActions(true)
        let totalHeight = calendar.calendarCollectionViewLayout.collectionViewContentSize.height
        calendar.collectionViewTopAnchor?.constant = -totalHeight
        calendar.layoutIfNeeded()
        CATransaction.setDisableActions(false)
        
        let offset = calculateOffsetForProgress(attributes: attributes, progress: 0)
        calendar.collectionViewTopAnchor?.constant = offset
        
        CATransaction.commit()
    }
}
