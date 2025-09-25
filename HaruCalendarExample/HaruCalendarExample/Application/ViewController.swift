//
//  ViewController.swift
//  HaruCalendarExample
//
//  Created by rick on 9/22/25.
//

import UIKit
import HaruCalendar

class ViewController: UIViewController {
    
    let calendarView = HaruCalendarView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
//        calendarView.delegate = self
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
//
//extension ViewController: HaruCalendarDelegate {
//    func calendar(_ calendar: HaruCalendar, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition) {
//        if monthPosition == .next || monthPosition == .previous {
//            calendar.setCurrentPage(date, animated: true)
//        }
//        print("Selected date: \(date)")
//    }
//}
