//
//  File.swift
//  HaruCalendar
//
//  Created by rick on 9/25/25.
//

import UIKit

open class HaruCalendarCollectionViewCell: UICollectionViewCell {
    weak var calendarView: HaruCalendarView?
    
    private static let defaultBounceAnimationDuration: CGFloat = 0.15
    
    private let shapeLayer = CAShapeLayer()
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.addSublayer(shapeLayer)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    public func config(from date: Date, monthPosition: HaruCalendarMonthPosition, scope: HaruCalendarScope) {
        guard let calendar = calendarView?.calendar else { return }
        let day = calendar.component(.day, from: date)
        label.text = "\(day)"
        
        if scope == .month {
            if monthPosition == .current {
                label.textColor = .label
            } else {
                label.textColor = .secondaryLabel
            }
        } else {
            label.textColor = .label
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        shapeLayer.cornerRadius = bounds.height / 2
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HaruCalendarCollectionViewCell {
    func performSelecting() {
        shapeLayer.opacity = 1
        
        // Create bounce animation
        let animationGroup = CAAnimationGroup()
        
        let zoomOut = CABasicAnimation(keyPath: "transform.scale")
        zoomOut.fromValue = 0.3
        zoomOut.toValue = 1.2
        zoomOut.duration = Self.defaultBounceAnimationDuration * 3/4
        
        let zoomIn = CABasicAnimation(keyPath: "transform.scale")
        zoomIn.fromValue = 1.2
        zoomIn.toValue = 1.0
        zoomIn.beginTime = Self.defaultBounceAnimationDuration * 3/4
        zoomIn.duration = Self.defaultBounceAnimationDuration * 1/4
        
        animationGroup.duration = Self.defaultBounceAnimationDuration
        animationGroup.animations = [zoomOut, zoomIn]
        
        shapeLayer.add(animationGroup, forKey: "bounce")
//        configureAppearance()
    }
}

extension UICollectionViewCell {
    static var identifier: String { String(describing: self) }
}
