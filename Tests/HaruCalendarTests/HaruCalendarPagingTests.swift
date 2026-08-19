import Testing
import UIKit
@testable import HaruCalendar

final class PagingProbeCell: UICollectionViewCell, HaruCalendarCell {
    func configure(date: Date, monthPosition: HaruCalendarMonthPosition, scope: HaruCalendarScope) {}
    func setCalendarSelected(_ selected: Bool) {}
    func updateAppearance() {}
}

@MainActor
final class PagingProbeSource: NSObject, HaruCalendarViewDataSource {
    func heightForRow(_ calendar: HaruCalendarView) -> CGFloat? { 50 }

    func calendar(_ calendar: HaruCalendarView, cellForItemAt date: Date, at indexPath: IndexPath) -> (any HaruCalendarCell) {
        calendar.calendarCollectionView.dequeueReusableCell(
            withReuseIdentifier: "probe",
            for: indexPath
        ) as! PagingProbeCell
    }
}

@MainActor
@Test func everyWeekPageShowsAFullRow() {
    assertEveryPageShowsAFullGrid(scope: .week)
}

@MainActor
@Test func everyMonthPageShowsAFullGrid() {
    assertEveryPageShowsAFullGrid(scope: .month)
}

@MainActor
private func assertEveryPageShowsAFullGrid(scope: HaruCalendarScope, sourceLocation: SourceLocation = #_sourceLocation) {
    let source = PagingProbeSource()
    let calendarView = HaruCalendarView(scope: scope)
    calendarView.dataSource = source
    calendarView.register(PagingProbeCell.self, forCellWithReuseIdentifier: "probe")

    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    calendarView.frame = CGRect(x: 0, y: 0, width: 393, height: scope == .week ? 94 : 344)
    window.addSubview(calendarView)
    window.makeKeyAndVisible()
    calendarView.reloadCalendar()
    calendarView.layoutIfNeeded()

    let collectionView = calendarView.calendarCollectionView
    calendarView.scrollTo(date: Date(), animated: false)
    calendarView.layoutIfNeeded()

    let expected = scope == .week ? 7 : 42
    let base = collectionView.contentOffset.x
    let width = collectionView.bounds.width

    for page in -5 ... 5 {
        collectionView.contentOffset = CGPoint(x: base + CGFloat(page) * width, y: 0)
        calendarView.layoutIfNeeded()

        let section = collectionView.currentSection
        let items = collectionView.indexPathsForVisibleItems.filter { $0.section == section }
        #expect(
            items.count == expected,
            "page \(page) of \(scope) showed \(items.count) of \(expected) cells",
            sourceLocation: sourceLocation
        )
    }

    _ = (source, window)
}
