//
//  HaruWeekdayView.swift
//  HaruCalendar
//
//  Created by rick on 10/1/25.
//

import UIKit

/// Default weekday header.
///
/// Customize it in place through its appearance properties, subclass it to
/// override `title(for:calendar:)` / `configureLabel(_:at:)`, or replace it
/// entirely with any `HaruCalendarWeekdayView` conforming view.
open class HaruWeekdayView: UIView, HaruCalendarWeekdayView {

    /// Which set of weekday symbols the default titles are taken from.
    public enum SymbolStyle: Hashable, Sendable {
        /// e.g. "S", "M" (`Calendar.veryShortWeekdaySymbols`)
        case veryShort
        /// e.g. "Sun", "Mon" (`Calendar.shortWeekdaySymbols`)
        case short
        /// e.g. "Sunday", "Monday" (`Calendar.weekdaySymbols`)
        case full
    }

    /// The seven labels, ordered left to right starting at `Calendar.firstWeekday`.
    public private(set) lazy var labels: [UILabel] = {
        (0 ..< 7).map { _ in UILabel() }
    }()

    /// Symbol set used when `weekdaySymbols` is `nil`. Defaults to `.short`.
    open var symbolStyle: SymbolStyle = .short {
        didSet { updateLabels() }
    }

    /// Overrides the calendar supplied symbols. Must contain 7 entries,
    /// ordered starting at `Calendar.firstWeekday`. Defaults to `nil`.
    open var weekdaySymbols: [String]? {
        didSet { updateLabels() }
    }

    /// Overrides the locale used for the weekday symbols.
    ///
    /// `nil` (the default) uses the locale of the calendar passed to
    /// `configure(calendar:)`, i.e. `Locale.current` in most apps. Set this to
    /// pin the header to a language regardless of device settings.
    open var locale: Locale? {
        didSet { updateLabels() }
    }

    /// Font applied to every label. Defaults to `.systemFont(ofSize: 14)`.
    open var font: UIFont = .systemFont(ofSize: 14) {
        didSet { updateLabels() }
    }

    /// Text color applied to every label. Defaults to `.label`.
    open var textColor: UIColor = .label {
        didSet { updateLabels() }
    }

    /// Per-index text color, e.g. to tint weekends. Index 0 is the leftmost
    /// column. Returning `nil` falls back to `textColor`. Defaults to `nil`.
    open var textColorProvider: ((Int) -> UIColor?)? {
        didSet { updateLabels() }
    }

    /// Height of the header. Defaults to 44.
    ///
    /// After changing it, call `invalidateIntrinsicContentSize()` on the
    /// owning `HaruCalendarView` so the calendar height is recalculated.
    open var weekdayHeight: CGFloat = 44 {
        didSet {
            guard weekdayHeight != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }

    /// Calendar the header is currently configured for.
    public private(set) var calendar: Calendar = .current

    public let stackView = UIStackView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupLayout()
        updateLabels()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        labels.forEach { stackView.addArrangedSubview($0) }
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

    open func configure(calendar: Calendar) {
        self.calendar = calendar
        updateLabels()
    }

    /// Title for the column at `index` (0 is the leftmost column, which
    /// corresponds to `calendar.firstWeekday`). Override to supply custom text.
    open func title(for index: Int, calendar: Calendar) -> String {
        if let weekdaySymbols, weekdaySymbols.indices.contains(index) {
            return weekdaySymbols[index]
        }

        var source = calendar
        if let locale {
            source.locale = locale
        } else if source.locale == nil || source.locale?.identifier.isEmpty == true {
            // A Calendar built with Calendar(identifier:) carries an empty
            // locale, for which Foundation returns English symbols.
            source.locale = .current
        }

        let symbols: [String]
        switch symbolStyle {
        case .veryShort: symbols = source.veryShortWeekdaySymbols
        case .short: symbols = source.shortWeekdaySymbols
        case .full: symbols = source.weekdaySymbols
        }

        guard symbols.count == 7 else { return "" }
        // Symbols are Sunday-first; rotate so the first column matches firstWeekday.
        return symbols[(index + source.firstWeekday - 1) % 7]
    }

    /// Applies appearance to a single label. Override for per-column styling.
    open func configureLabel(_ label: UILabel, at index: Int) {
        label.textAlignment = .center
        label.text = title(for: index, calendar: calendar)
        label.font = font
        label.textColor = textColorProvider?(index) ?? textColor
    }

    /// Reapplies titles and appearance to every label.
    public func updateLabels() {
        for index in labels.indices {
            configureLabel(labels[index], at: index)
        }
    }

    open override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: weekdayHeight)
    }
}
