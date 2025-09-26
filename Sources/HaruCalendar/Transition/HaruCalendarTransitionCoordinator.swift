//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/26/25.
//

import UIKit

enum FSCalendarTransitionState {
    case idle, changing, finished
}

@MainActor
final class HaruCalendarTransitionCoordinator {
    var state: FSCalendarTransitionState = .idle
    var cachedMonthSize: CGSize?
    var representingScope: HaruCalendarScope?
    var attributes: HaruCalendarTransitionAttributes?
    
    let calendar: HaruCalendarView
    
    init(calendar: HaruCalendarView) {
        self.calendar = calendar
    }
    
    func performTransition(fromScope: HaruCalendarScope, toScope: HaruCalendarScope, animated: Bool) {
        state = .changing
        let attributes = createTransitionAttributesTargetingScope(sourceScope: fromScope,targetScope: toScope)
        if toScope == .month {
            calendar.reloadData()
//            calendar.calendarCollectionView.reloadData()
            
            
            let offset = calculateOffsetForProgress(attributes: attributes, progress: 0)
            print(offset)
            calendar.collectionViewTopAnchor?.constant = offset
            calendar.layoutIfNeeded()
        }
        
        performTransition(attributes: attributes, fromProgress: 0, toProgress: 1, animated: animated)
    }
    
    func performBoundingRectTransitionFromMonth(fromMonth: Date, toMonth: Date, duration: CGFloat) {
        
    }
    
    func performTransition(attributes: HaruCalendarTransitionAttributes, fromProgress: CGFloat, toProgress: CGFloat, animated: Bool) {
        
        let offset = calculateOffsetForProgress(attributes: attributes, progress: toProgress)
        calendar.collectionViewTopAnchor?.constant = offset
        calendar.invalidateIntrinsicContentSize()
        
        UIView.animate(withDuration: 5, delay: 0, options: .curveEaseInOut) { [weak self] in
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
}

extension HaruCalendarTransitionCoordinator {
    func createTransitionAttributesTargetingScope(sourceScope: HaruCalendarScope, targetScope: HaruCalendarScope) -> HaruCalendarTransitionAttributes {
        // get focusedDate
        var candidates: [Date] = []
        
        if let selectedDate = calendar.selectedDate {
            candidates.append(selectedDate)
        }
        
        candidates.append(calendar.today)
        
        if targetScope == .week {
            candidates.append(calendar.currentPage)
        } else if let date = calendar.calendar.date(byAdding: .day, value: 3, to: calendar.currentPage) {
            candidates.append(date)
        }
        
        let focusedDate = candidates.filter {
            let indexPath = calendar.indexPath(for: $0, scope: sourceScope)
            let currentSection = calendar.indexPath(for: calendar.currentPage, scope: sourceScope)?.section
            return indexPath?.section == currentSection
        }.first
        
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
        
        if attributes.targetScope == .week {
            calendar.reloadData()
//            calendar.calendarCollectionView.reloadData()
        }
        
        calendar.collectionViewTopAnchor?.constant = 0
        calendar.superview?.layoutIfNeeded()
    }
}
