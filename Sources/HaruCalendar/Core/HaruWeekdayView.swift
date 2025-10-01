//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 10/1/25.
//

import UIKit

final class HaruWeekdayView: UIView {
    
    lazy var labels: [UILabel] = {
        (0 ..< 7).map { _ in UILabel() }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        let stackView = UIStackView(arrangedSubviews: labels)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func setupLabels(with calendar: Calendar) {
        for idx in labels.indices {
            let label = labels[idx]
            label.textAlignment = .center
            label.text = calendar.shortWeekdaySymbols[idx]
            label.textColor = .label
            label.font = .systemFont(ofSize: 14)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: -1, height: 44)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
