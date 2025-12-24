//
//  CustomCalendarCell.swift
//  HaruCalendarExample
//
//  Created by Claude on 12/24/25.
//

import UIKit
import HaruCalendar

class CustomCalendarCell: UICollectionViewCell, HaruCalendarCell {

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    private let selectionIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 20
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(selectionIndicator)
        contentView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            selectionIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 40),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 40),

            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - HaruCalendarCell Conformance

    func configure(date: Date, monthPosition: HaruCalendarMonthPosition, scope: HaruCalendarScope) {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        dateLabel.text = "\(day)"

        // Style based on month position
        if scope == .month {
            dateLabel.textColor = monthPosition == .current ? .label : .secondaryLabel
        } else {
            dateLabel.textColor = .label
        }
    }

    func setCalendarSelected(_ selected: Bool) {
        updateAppearance(selected: selected)
    }

    func updateAppearance() {
        updateAppearance(selected: isSelected)
    }

    private func updateAppearance(selected: Bool) {
        selectionIndicator.alpha = selected ? 1.0 : 0.0
//        dateLabel.textColor = selected ? .white : .label
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        selectionIndicator.alpha = 0.0
        dateLabel.textColor = .label
    }
}
