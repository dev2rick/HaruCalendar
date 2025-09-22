//
//  HaruCalendarPreview.swift
//  HaruCalendar
//
//  Created by rick on 9/22/25.
//

import SwiftUI

struct HaruCalendarPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let calendar = HaruCalendar()
        calendar.delegate = context.coordinator
        return calendar
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
    
    class Coordinator: NSObject, HaruCalendarDelegate {
        func calendar(_ calendar: HaruCalendar, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            print(formatter.string(from: date))
        }
    }
}

#Preview {
    HaruCalendarPreview()
}
