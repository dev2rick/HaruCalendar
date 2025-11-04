//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/26/25.
//

import Foundation

public struct HaruCalendarTransitionAttributes: Hashable {
    let sourceBounds: CGRect
    let targetBounds: CGRect
    let sourcePage: Date?
    let targetPage: Date?
    let focusedRow: Int
    let focusedDate: Date?
    let targetScope: HaruCalendarScope
}
