//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 11/4/25.
//

import Foundation
import UIKit

public extension HaruCalendarView {
    func performTransition(fromScope: HaruCalendarScope, toScope: HaruCalendarScope, animated: Bool) {
        transitionState = .animating(to: toScope)
        let attributes = createTransitionAttributesTargetingScope(sourceScope: fromScope,targetScope: toScope)
        if toScope == .month {
            prepareWeekToMonthTransition(from: attributes)
        }
        
        performTransition(attributes: attributes, toProgress: 1, animated: animated)
    }
    
    func createTransitionAttributesTargetingScope(sourceScope: HaruCalendarScope, targetScope: HaruCalendarScope) -> HaruCalendarTransitionAttributes {
        // get focusedDate
        
        let candidates: [Date] = [selectedDate, today, currentPage]
        
        let scope = targetScope == .week ? sourceScope : targetScope
        
        let focusedDate = candidates.first {
            let indexPath = indexPath(for: $0, scope: scope)
            let currentSection = self.indexPath(for: currentPage, scope: scope)?.section
            return indexPath?.section == currentSection
        }
        // get focusedRow
        let focusedRow: Int
        if let focusedDate, let indexPath = indexPath(for: focusedDate, scope: .month) {
            focusedRow = coordinate(for: indexPath).row
        } else {
            focusedRow = 0
        }
        
        // get targetPage
        let targetPage: Date?
        if let focusedDate {
            if targetScope == .month {
                targetPage = calendar.firstDayOfMonth(for: focusedDate)
            } else {
                targetPage = calendar.middleDayOfWeek(focusedDate)
            }
        } else {
            targetPage = nil
        }
        
        let targetBounds = boundingRectForScope(targetScope)
        
        return .init(
            sourceBounds: bounds,
            targetBounds: targetBounds,
            sourcePage: currentPage,
            targetPage: targetPage,
            focusedRow: focusedRow,
            focusedDate: focusedDate,
            targetScope: targetScope
        )
    }
    
    func boundingRectForScope(_ scope: HaruCalendarScope) -> CGRect {
        let contentSize = sizeThatFits(frame.size, scope: scope)
        return CGRect(origin: .zero, size: contentSize)
    }
    
    func prepareWeekToMonthTransition(from attributes: HaruCalendarTransitionAttributes) {
        scope = attributes.targetScope
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        reloadCalendar(for: attributes.targetPage)
        layoutIfNeeded()
        
        CATransaction.setDisableActions(true)
        let totalHeight = calendarCollectionViewLayout.collectionViewContentSize.height
        collectionViewTopAnchor?.constant = -totalHeight
        layoutIfNeeded()
        CATransaction.setDisableActions(false)
        
        let offset = calculateOffsetForProgress(attributes: attributes, progress: 0)
        collectionViewTopAnchor?.constant = offset
        layoutIfNeeded()
        CATransaction.commit()
    }
    
    func calculateOffsetForProgress(attributes: HaruCalendarTransitionAttributes, progress: CGFloat) -> CGFloat {
        guard
            let focusedDate = attributes.focusedDate,
            let indexPath = indexPath(for: focusedDate, scope: .month),
            let frame = calendarCollectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame else {
            return 0
        }
        
        let ratio = attributes.targetScope == .week ? progress : (1 - progress)
        let offset = (-frame.origin.y + calendarCollectionViewLayout.sectionInsets.top) * ratio
        return offset
    }
    
    func performTransition(attributes: HaruCalendarTransitionAttributes, toProgress: CGFloat, animated: Bool) {
        scope = attributes.targetScope
        let offset = calculateOffsetForProgress(attributes: attributes, progress: toProgress)
        collectionViewTopAnchor?.constant = offset
        invalidateIntrinsicContentSize()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
            self?.superview?.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.performTransitionCompletion(from: attributes)
        }
    }
    
    func performTransitionCompletion(from attributes: HaruCalendarTransitionAttributes) {
        collectionViewTopAnchor?.constant = 0
        superview?.layoutIfNeeded()
        
        if attributes.targetScope == .week {
            reloadCalendar(for: attributes.targetPage)
        }
        transitionState = .idle
    }
}
