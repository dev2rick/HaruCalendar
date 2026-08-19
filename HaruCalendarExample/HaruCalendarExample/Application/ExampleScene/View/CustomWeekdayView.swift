//
//  CustomWeekdayView.swift
//  HaruCalendarExample
//
//  Created by rick on 8/19/26.
//

import UIKit
import HaruCalendar

/// Example of a fully custom weekday header built from scratch.
///
/// Conforming to `HaruCalendarWeekdayView` is all `HaruCalendarView` needs:
/// `configure(calendar:)` for the symbols and `weekdayHeight` for the layout.
final class CustomWeekdayView: UIView, HaruCalendarWeekdayView {

    var weekdayHeight: CGFloat { 36 }

    private let stackView = UIStackView()
    private lazy var labels: [UILabel] = (0 ..< 7).map { _ in UILabel() }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12

        labels.forEach { stackView.addArrangedSubview($0) }
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(calendar: Calendar) {
        let symbols = calendar.veryShortWeekdaySymbols
        for index in labels.indices {
            // Symbols are Sunday-first; rotate to match the grid's firstWeekday.
            let weekday = (index + calendar.firstWeekday - 1) % 7
            let label = labels[index]
            label.text = symbols[weekday].uppercased()
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            switch weekday {
            case 0: label.textColor = .systemRed      // Sunday
            case 6: label.textColor = .systemBlue     // Saturday
            default: label.textColor = .secondaryLabel
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: weekdayHeight)
    }
}
