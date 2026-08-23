# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HaruCalendar is a Swift Package providing native calendar functionality for iOS, designed as a Swift alternative to FSCalendar. The project is built entirely with UIKit and focuses on interactive calendar views with smooth scope transitions between month and week views.

**Key Technology**: UIKit-based, iOS 13.0+, Swift 5.5+

## Build & Test Commands

### Build the package
```bash
swift build
```
Note: This will fail on non-macOS platforms since UIKit is iOS-specific.

### Run tests
```bash
swift test
```

### Open in Xcode
```bash
open Package.swift
```

### Build and run the example app
```bash
open HaruCalendarExample/HaruCalendarExample.xcodeproj
```
Then build and run in Xcode targeting an iOS Simulator.

## Core Architecture

### State Management with TransitionState Enum

The view uses an enum-based state machine to track transition state:

```swift
public enum TransitionState: Hashable {
    case idle
    case interactive(attributes: HaruCalendarTransitionAttributes)
    case animating(to: HaruCalendarScope)
}
```

**Important**: All transition logic checks `transitionState` to prevent invalid operations. When handling enum cases with associated values in guards:

```swift
guard case .interactive(let attributes) = transitionState else { return }
```

### Three-Layer View Hierarchy

1. **HaruCalendarView** (Main Container)
   - Main public API and UIView container
   - Manages two subviews: a weekday header (`any HaruCalendarWeekdayView`, default `HaruWeekdayView`) and `HaruCalendarCollectionView` (calendar grid)
   - Uses intrinsic content sizing for flexible layout
   - **Critical Property**: `transitionHeight: CGFloat?` - when set, overrides intrinsic content size during animations

2. **HaruCalendarCollectionView + Layout**
   - Horizontal paging collection view with 7-column grid layout
   - Custom `UICollectionViewLayout` with aggressive caching (only recalculates when size/section count changes)
   - Each section = one month (42 cells: 6 rows × 7 days) or one week (7 cells)
   - **Important**: Layout uses cached `itemAttributes` - invalidate carefully when scope changes

3. **Transition Extensions** (`HaruCalendarView+Transition.swift`, `HaruCalendarView+InteractiveGesture.swift`)
   - All scope transition logic is in extensions, not a separate coordinator
   - Two transition modes:
     - **Programmatic**: via `performTransition(fromScope:toScope:animated:)`
     - **Interactive**: pan gesture on reference scroll view (typically UITableView)
   - **Critical Method**: `prepareWeekToMonthTransition(from:)` - uses `CATransaction` to position layout before animating

### Scope System

**HaruCalendarScope** enum: `.month` (6 rows) or `.week` (1 row)

Scope transitions modify:
- Calendar height (via `transitionHeight` → `intrinsicContentSize`)
- Collection view top constraint (`collectionViewTopAnchor?.constant`)
- Collection view data (via `reloadCalendar(for:)`)
- TransitionState (`.idle` → `.animating(to:)` → `.idle`)

### Data Flow & Caching

**Date Calculations** (`Extensions/HaruCalendarView+Calculator.swift`)
- Maps IndexPath ↔ Date based on current scope
- Caches: `months`, `monthHeads`, `weeks`, `rowCounts`
- **Important**: All caches cleared in `reloadSections()` - call when date range changes

**Layout Caching** (`Core/HaruCalendarCollectionViewLayout.swift`)
- Only recalculates when `collectionViewSize != currentSize || numberOfSections != currentSections`
- Caches `itemAttributes`, `widths`, `heights`, `lefts`, `tops`
- **Critical**: This aggressive caching can cause stale layouts - force invalidation with `invalidateLayout()` when needed
- `shouldInvalidateLayout(forBoundsChange:)` returns `true`: horizontal paging only moves the bounds, and without invalidation UICollectionView stops re-querying the layout, leaving the rightmost column cell-less when scrolling back to a visited page
- `layoutAttributesForItem(at:)` returns **copies** of the cached attributes; UIKit mutates the objects a layout hands it

### Interactive Transition Mechanics

Interactive transitions work via reference scroll view integration:

1. Reference scroll view (e.g., UITableView) shares superview with calendar
2. Pan gesture added to shared superview via `setReferenceScrollView(_:)`
3. Gesture only triggers when scroll view at top (`contentOffset.y <= -contentInset.top`)
4. Progress calculated as: `translation / abs(sourceBounds.height - targetBounds.height)`
5. During drag: `transitionHeight` updated → `intrinsicContentSize` changes
6. On end: finalizes transition with animation, updating `transitionState`

**Week-to-Month Preparation** (most complex transition):
```swift
CATransaction.begin()
CATransaction.setDisableActions(false)
// Reload data in month scope
reloadCalendar(for: targetPage)

CATransaction.setDisableActions(true)
// Position collection view off-screen at bottom
collectionViewTopAnchor?.constant = -totalHeight
layoutIfNeeded()

CATransaction.setDisableActions(false)
// Calculate interpolated starting position
collectionViewTopAnchor?.constant = offset
CATransaction.commit()
```

This ensures the month layout is calculated before animating upward.

## File Organization

```
Sources/HaruCalendar/
├── Core/               # Main views (HaruCalendarView, CollectionView, Cell, Layout, WeekdayView)
├── Extensions/         # View extensions (Calculator, Transition, InteractiveGesture)
├── Protocols/          # DataSource & Delegate protocols
└── Types/              # Enums and data structures (Scope, MonthPosition, TransitionAttributes)
```

**Note**: There is no separate coordinator class - all transition logic lives in view extensions.

## Key Implementation Patterns

### Proper Calendar Integration
```swift
let calendarView = HaruCalendarView(scope: .month)
calendarView.dataSource = self  // Provide heightForRow
calendarView.delegate = self    // Handle selection/page changes

// For interactive transitions, provide reference scroll view
calendarView.setReferenceScrollView(tableView)
```

### Scope Changes
```swift
// Programmatic (animated)
calendarView.performTransition(fromScope: .month, toScope: .week, animated: true)

// Interactive via gesture
// Automatically handled if reference scroll view is set via setReferenceScrollView(_:)
```

### Weekday Header Customization
The header is any view conforming to `HaruCalendarWeekdayView` (`configure(calendar:)` + `weekdayHeight`):

```swift
// Inject at init, or swap later
let calendarView = HaruCalendarView(scope: .month, weekdayView: MyWeekdayView())
calendarView.setWeekdayView(MyWeekdayView())  // ignored unless transitionState == .idle

// Or tweak the default header in place
(calendarView.weekdayView as? HaruWeekdayView)?.symbolStyle = .veryShort
```

The gap between header and grid is `calendarView.weekdaySpacing` (default 0).
It is the resting value of `collectionViewTopAnchor`, so transitions must go
through `setCollectionViewOffset(_:)` (0 = at rest) rather than setting the
constraint constant directly.

`weekdayHeight` feeds `intrinsicContentSize`; changing it later requires
`calendarView.invalidateIntrinsicContentSize()`. Replacing the header rebuilds
`collectionViewTopAnchor` (it is pinned to the header's bottom), preserving the
current constant.

### Date Selection
Implement `HaruCalendarViewDelegate`:
- `calendar(_:shouldSelect:at:)` - gate selection
- `calendar(_:didSelect:at:)` - handle selection
- `calendarCurrentPageDidChange(_:)` - page scroll events

`selectedDate` is normalized to the start of the day and every comparison against
it is day-granular, so a `Date` carrying a time component still matches its cell.

Selecting from outside (a "today" button, state pushed down from SwiftUI):

```swift
calendarView.select(date)                              // pages to the date, animated
calendarView.select(date, scrollToDate: false)         // selection only
```

`select(_:scrollToDate:animated:)` deliberately reports **nothing** back — no
`didSelect`, and no `calendarCurrentPageDidChange` for the scroll it starts.
The caller already knows the date it passed in; echoing it back is what makes a
one-way data flow (SwiftUI, Redux-ish stores) loop on itself. It is also safe to
call before the calendar has loaded: the pending `reloadCalendar()` picks up both
the selection and `currentPage`.

## Important Constraints

- **Never skip layout preparation** in week→month transitions - `prepareWeekToMonthTransition(from:)` must run first
- **Always call `reloadSections()`** before `reloadData()` when date range changes - clears critical caches
- **Constraint modification during animation** - `collectionViewTopAnchor` is manipulated directly; ensure superview exists
- **Scope changes update TransitionState** - check state before starting new transitions to prevent conflicts
- **No coordinator pattern** - all logic is in the view and its extensions
- **Weekday header swaps only while idle** - `setWeekdayView(_:)` rebuilds `collectionViewTopAnchor`, so it is a no-op during a transition

## Development Context

- Project inspired by FSCalendar but built from scratch in Swift
- UIKit-only; SwiftUI support requires wrapping in `UIViewRepresentable` or `UIViewControllerRepresentable`
- Example app demonstrates UITableView integration with interactive transitions
- Architecture changed from coordinator pattern to extension-based approach for simplicity
