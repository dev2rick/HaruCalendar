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
    let tableView = UITableView()
    
    var items: [String] {
        (1 ... 100).map { "Item: #\($0)" }
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.delegate = self
        calendarView.dataSource = self
        view.addSubview(calendarView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(
            ExampleTableViewCell.self,
            forCellReuseIdentifier: ExampleTableViewCell.identifier
        )
        view.addSubview(tableView)
        
        calendarView.setReferenceScrollView(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: calendarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func scopeChanged(_ sender: UISegmentedControl) {
        let newScope: HaruCalendarScope = sender.selectedSegmentIndex == 0 ? .week : .month
        
        calendarView.setScope(newScope)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExampleTableViewCell.identifier, for: indexPath) as! ExampleTableViewCell
        cell.config(text: items[indexPath.row])
        
        return cell
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
