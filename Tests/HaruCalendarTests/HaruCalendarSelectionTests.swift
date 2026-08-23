import Testing
import UIKit
@testable import HaruCalendar

final class SelectionProbeCell: UICollectionViewCell, HaruCalendarCell {
    private(set) var date: Date?
    private(set) var isCalendarSelected = false

    func configure(date: Date, monthPosition: HaruCalendarMonthPosition, scope: HaruCalendarScope) {
        self.date = date
    }

    func setCalendarSelected(_ selected: Bool) {
        isCalendarSelected = selected
    }

    func updateAppearance() {}

    override func prepareForReuse() {
        super.prepareForReuse()
        date = nil
        isCalendarSelected = false
    }
}

@MainActor
final class SelectionProbeSource: NSObject, HaruCalendarViewDataSource {
    func heightForRow(_ calendar: HaruCalendarView) -> CGFloat? { 50 }

    func calendar(_ calendar: HaruCalendarView, cellForItemAt date: Date, at indexPath: IndexPath) -> (any HaruCalendarCell) {
        calendar.calendarCollectionView.dequeueReusableCell(
            withReuseIdentifier: "probe",
            for: indexPath
        ) as! SelectionProbeCell
    }
}

@MainActor
final class SelectionProbeDelegate: NSObject, HaruCalendarViewDelegate {
    private(set) var selectedDates: [Date] = []
    private(set) var pageChanges = 0

    func calendar(_ calendar: HaruCalendarView, didSelect date: Date, at monthPosition: HaruCalendarMonthPosition) {
        selectedDates.append(date)
    }

    func calendarCurrentPageDidChange(_ calendar: HaruCalendarView) {
        pageChanges += 1
    }
}

@MainActor
private struct SelectionProbe {
    let calendarView: HaruCalendarView
    let source: SelectionProbeSource
    let delegate: SelectionProbeDelegate
    let window: UIWindow

    init(scope: HaruCalendarScope) {
        source = SelectionProbeSource()
        delegate = SelectionProbeDelegate()
        calendarView = HaruCalendarView(scope: scope)
        calendarView.dataSource = source
        calendarView.delegate = delegate
        calendarView.register(SelectionProbeCell.self, forCellWithReuseIdentifier: "probe")

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        calendarView.frame = CGRect(x: 0, y: 0, width: 393, height: scope == .week ? 94 : 344)
        window.addSubview(calendarView)
        window.makeKeyAndVisible()
        calendarView.reloadCalendar()
        calendarView.layoutIfNeeded()
    }

    /// The visible cell showing `date`, if any.
    func cell(for date: Date) -> SelectionProbeCell? {
        let collectionView = calendarView.calendarCollectionView

        return collectionView.indexPathsForVisibleItems
            .filter { calendarView.date(for: $0).map { calendarView.calendar.isDate($0, inSameDayAs: date) } ?? false }
            .compactMap { collectionView.cellForItem(at: $0) as? SelectionProbeCell }
            .first
    }

    func scrollPages(_ pages: Int) {
        let collectionView = calendarView.calendarCollectionView
        collectionView.contentOffset.x += CGFloat(pages) * collectionView.bounds.width
        calendarView.layoutIfNeeded()
    }
}

@MainActor
@Test func selectMarksTheCellEvenWhenTheDateCarriesATime() {
    let probe = SelectionProbe(scope: .week)
    let calendar = probe.calendarView.calendar
    let afternoon = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: Date())!

    probe.calendarView.select(afternoon, animated: false)
    probe.calendarView.layoutIfNeeded()

    #expect(probe.cell(for: afternoon)?.isCalendarSelected == true)
    #expect(probe.calendarView.selectedDate == calendar.startOfDay(for: afternoon))
}

@MainActor
@Test func selectReportsNothingBackToTheDelegate() {
    let probe = SelectionProbe(scope: .week)
    let calendar = probe.calendarView.calendar
    let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: Date())!

    probe.calendarView.select(nextWeek, animated: false)
    probe.calendarView.layoutIfNeeded()

    #expect(probe.delegate.selectedDates.isEmpty)
    #expect(probe.delegate.pageChanges == 0)
    #expect(probe.calendarView.currentPage == calendar.dateInterval(of: .weekOfYear, for: nextWeek)?.start)
}

@MainActor
@Test func selectionSurvivesScrollingAwayAndBack() {
    let probe = SelectionProbe(scope: .week)
    let calendar = probe.calendarView.calendar
    let midweek = calendar.date(byAdding: .day, value: 3, to: calendar.firstDayOfWeek(for: Date())!)!

    probe.calendarView.select(midweek, animated: false)
    probe.calendarView.layoutIfNeeded()
    #expect(probe.cell(for: midweek)?.isCalendarSelected == true)

    probe.scrollPages(2)
    #expect(probe.cell(for: midweek) == nil)

    probe.scrollPages(-2)
    #expect(probe.cell(for: midweek)?.isCalendarSelected == true)
}

@MainActor
@Test func selectingAnotherDayClearsThePreviousCell() {
    let probe = SelectionProbe(scope: .week)
    let calendar = probe.calendarView.calendar
    let weekStart = calendar.firstDayOfWeek(for: Date())!
    // Both days sit on the same page, so both cells stay visible.
    let first = calendar.date(byAdding: .day, value: 1, to: weekStart)!
    let second = calendar.date(byAdding: .day, value: 2, to: weekStart)!

    probe.calendarView.select(first, animated: false)
    probe.calendarView.layoutIfNeeded()
    probe.calendarView.select(second, animated: false)
    probe.calendarView.layoutIfNeeded()

    #expect(probe.cell(for: first)?.isCalendarSelected == false)
    #expect(probe.cell(for: second)?.isCalendarSelected == true)
}

@MainActor
@Test func selectOutsideTheAllowedRangeIsIgnored() {
    let probe = SelectionProbe(scope: .week)
    let calendar = probe.calendarView.calendar
    let today = calendar.startOfDay(for: Date())
    let inRange = calendar.date(byAdding: .day, value: 2, to: today)!

    probe.calendarView.minimumDate = today
    probe.calendarView.maximumDate = calendar.date(byAdding: .day, value: 7, to: today)!
    probe.calendarView.reloadCalendar()
    probe.calendarView.layoutIfNeeded()

    probe.calendarView.select(inRange, animated: false)
    probe.calendarView.select(calendar.date(byAdding: .day, value: -30, to: today)!, animated: false)

    #expect(probe.calendarView.selectedDate == inRange)
}
