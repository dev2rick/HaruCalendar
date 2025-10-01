//
//  ViewController.swift
//  HaruCalendarExample
//
//  Created by rick on 9/22/25.
//

import UIKit
import HaruCalendar

class ViewController: UIViewController {
    
    let calendarView = HaruCalendarView(scope: .month)
    let scopeToggleControl = UISegmentedControl(items: ["Week", "Month"])
    let scrollView = UIScrollView()
    let contentView = UIView()
    let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        scopeToggleControl.selectedSegmentIndex = 1
        scopeToggleControl.addTarget(self, action: #selector(scopeChanged(_:)), for: .valueChanged)
        scopeToggleControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scopeToggleControl)
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.delegate = self
        calendarView.dataSource = self
        view.addSubview(calendarView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.backgroundColor = .red
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        scrollView.alwaysBounceVertical = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        label.text = "Hello, world!"
        calendarView.setReferenceScrollView(scrollView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scope toggle constraints
            scopeToggleControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scopeToggleControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scopeToggleControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scopeToggleControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Calendar view constraints - height will be determined by intrinsicContentSize
            calendarView.topAnchor.constraint(equalTo: scopeToggleControl.bottomAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            calendarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            scrollView.topAnchor.constraint(equalTo: calendarView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 1000)
        ])
    }
    
    @objc private func scopeChanged(_ sender: UISegmentedControl) {
        let newScope: HaruCalendarScope = sender.selectedSegmentIndex == 0 ? .week : .month
        
        calendarView.setScope(newScope)
    }
}

extension ViewController: HaruCalendarViewDelegate, HaruCalendarViewDataSource {
    func calendar(_ calendar: HaruCalendarView, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition) {
        print(date)
    }
    
    func calendarCurrentPageDidChange(_ calendar: HaruCalendarView) {
        print(calendar.currentPage)
    }
}
