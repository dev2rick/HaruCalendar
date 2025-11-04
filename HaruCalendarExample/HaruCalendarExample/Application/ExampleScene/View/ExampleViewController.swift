//
//  ViewController.swift
//  HaruCalendarExample
//
//  Created by rick on 9/22/25.
//

import UIKit
import HaruCalendar

class ExampleViewController: UIViewController {
    
    let calendarView = HaruCalendarView(scope: .month)
    let tableView = UITableView(frame: .zero, style: .grouped)
    
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
//        calendarView.coordinator = coordinator
        view.addSubview(calendarView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(
            ExampleTableViewCell.self,
            forCellReuseIdentifier: ExampleTableViewCell.identifier
        )
        view.addSubview(tableView)
//        coordinator.setReferenceScrollView(tableView)[p
//        calendarView.setReferenceScrollView(tableView)
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

extension ExampleViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExampleTableViewCell.identifier, for: indexPath) as! ExampleTableViewCell
        
        if indexPath.section == 0 {
            let text = indexPath.row == 0 ? "Month": "Week"
            cell.config(text: text)
        } else {
            cell.config(text: items[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let scope: HaruCalendarScope = indexPath.row == 0 ? .month : .week
            calendarView.setScope(scope)
        } else if let cell = tableView.cellForRow(at: indexPath) as? ExampleTableViewCell {
            print(cell.label.text)
        }
    }
}

extension ExampleViewController: HaruCalendarViewDelegate, HaruCalendarViewDataSource {
    func calendar(_ calendar: HaruCalendarView, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition) {
        print(date)
    }
    
    func calendarCurrentPageDidChange(_ calendar: HaruCalendarView) {
        print(calendar.currentPage)
    }
}
//
//struct PreviewCalendar: UIViewRepresentable {
//    func makeUIView(context: Context) -> some UIView {
//        let view = HaruCalendarView(scope: .month)
//        view.dataSource = context.coordinator
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
//    }
//    
//    @available(iOS 16.0, *)
//    func sizeThatFits(_ proposal: ProposedViewSize, uiView: HaruCalendarView, context: Context) -> CGSize? {
//        let size = CGSize(width: proposal.width ?? 0, height: 0)
//        return uiView.sizeThatFits(size, scope: uiView.scope)
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//    
//    
//    final class Coordinator: NSObject, HaruCalendarViewDataSource {
//        func heightForRow(_ calendar: HaruCalendarView) -> CGFloat? {
//            50
//        }
//    }
//}
//
//#Preview {
//    PreviewCalendar()
//        .background(Color.green)
//}
