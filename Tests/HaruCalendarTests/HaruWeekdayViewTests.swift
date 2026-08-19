import Testing
import UIKit
@testable import HaruCalendar

@MainActor
private func labels(of view: HaruWeekdayView) -> [String] {
    view.labels.map { $0.text ?? "" }
}

@MainActor
@Test func weekdayHeaderUsesCalendarLocale() {
    let view = HaruWeekdayView()

    var korean = Calendar(identifier: .gregorian)
    korean.locale = Locale(identifier: "ko_KR")
    view.configure(calendar: korean)
    #expect(labels(of: view) == ["일", "월", "화", "수", "목", "금", "토"])

    var english = Calendar(identifier: .gregorian)
    english.locale = Locale(identifier: "en_US")
    view.configure(calendar: english)
    #expect(labels(of: view) == ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
}

@MainActor
@Test func weekdayHeaderRespectsFirstWeekday() {
    var monday = Calendar(identifier: .gregorian)
    monday.locale = Locale(identifier: "ko_KR")
    monday.firstWeekday = 2

    let view = HaruWeekdayView()
    view.configure(calendar: monday)
    #expect(labels(of: view) == ["월", "화", "수", "목", "금", "토", "일"])
}

@MainActor
@Test func weekdayHeaderLocaleOverrideWins() {
    var english = Calendar(identifier: .gregorian)
    english.locale = Locale(identifier: "en_US")

    let view = HaruWeekdayView()
    view.locale = Locale(identifier: "ko_KR")
    view.configure(calendar: english)
    #expect(labels(of: view) == ["일", "월", "화", "수", "목", "금", "토"])
}

@MainActor
@Test func weekdayHeaderFallsBackWhenCalendarHasNoLocale() {
    var noLocale = Calendar(identifier: .gregorian)
    noLocale.locale = nil

    let view = HaruWeekdayView()
    view.configure(calendar: noLocale)
    #expect(labels(of: view) == Calendar.current.shortWeekdaySymbols)
}

@MainActor
@Test func customWeekdayViewCanReplaceTheDefault() {
    final class StubHeader: UIView, HaruCalendarWeekdayView {
        var configuredCalendar: Calendar?
        var weekdayHeight: CGFloat { 20 }
        func configure(calendar: Calendar) { configuredCalendar = calendar }
    }

    let stub = StubHeader()
    let calendarView = HaruCalendarView(scope: .week, weekdayView: stub)
    #expect(calendarView.weekdayView === stub)
    #expect(stub.configuredCalendar != nil)
    #expect(stub.superview === calendarView)

    let replacement = StubHeader()
    calendarView.setWeekdayView(replacement)
    #expect(calendarView.weekdayView === replacement)
    #expect(stub.superview == nil)
}

@MainActor
@Test func weekdaySpacingSeparatesHeaderFromGrid() {
    let source = PagingProbeSource()
    let calendarView = HaruCalendarView(scope: .week)
    calendarView.dataSource = source
    calendarView.register(PagingProbeCell.self, forCellWithReuseIdentifier: "probe")

    let baseHeight = calendarView.intrinsicContentSize.height
    calendarView.weekdaySpacing = 4

    #expect(calendarView.intrinsicContentSize.height == baseHeight + 4)

    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    calendarView.frame = CGRect(x: 0, y: 0, width: 393, height: calendarView.intrinsicContentSize.height)
    window.addSubview(calendarView)
    window.makeKeyAndVisible()
    calendarView.layoutIfNeeded()

    let gap = calendarView.calendarCollectionView.frame.minY - calendarView.weekdayView.frame.maxY
    #expect(gap == 4)
    _ = (source, window)
}
