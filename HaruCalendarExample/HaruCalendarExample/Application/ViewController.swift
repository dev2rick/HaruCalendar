//
//  ViewController.swift
//  HaruCalendarExample
//
//  Created by rick on 9/22/25.
//

import UIKit
import HaruCalendar

class ViewController: UIViewController {
    
    let calendarView = HaruCalendarView(scope: .week)
    let scopeToggleControl = UISegmentedControl(items: ["Week", "Month"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        scopeToggleControl.selectedSegmentIndex = 0
        scopeToggleControl.addTarget(self, action: #selector(scopeChanged(_:)), for: .valueChanged)
        scopeToggleControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scopeToggleControl)
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scope toggle constraints
            scopeToggleControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scopeToggleControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scopeToggleControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scopeToggleControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Calendar view constraints
            calendarView.topAnchor.constraint(equalTo: scopeToggleControl.bottomAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func scopeChanged(_ sender: UISegmentedControl) {
        let newScope: HaruCalendarScope = sender.selectedSegmentIndex == 0 ? .week : .month
        calendarView.setScope(newScope)
    }
}
