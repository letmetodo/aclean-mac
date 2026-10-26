import Foundation

@MainActor
struct P9CleanDetailLayoutTests {
    func runAll() {
        var passed = 0
        func check(_ value: Bool, _ message: String) {
            precondition(value, message)
            passed += 1
        }
        let first = Node(name: "first", size: 1)
        let second = Node(name: "second", size: 2)
        func group(_ id: String, _ items: [Node]) -> SmartAppCacheGroup {
            SmartAppCacheGroup(id: id, title: id, subtitle: "", appIcon: nil, fallbackSymbol: "folder", items: items)
        }
        let groups = [group("a", [first, second]), group("b", [first]), group("empty", [])]
        let collapsed = SmartCleanDetailRow.rows(groups: groups, expanded: [])
        check(collapsed.count == 3 && collapsed.allSatisfy(\.endsGroup), "collapsed groups expose headers only")
        let expanded = SmartCleanDetailRow.rows(groups: groups, expanded: ["a", "b", "empty"])
        check(expanded.count == 6, "each expanded item has its own lazy row")
        check(Set(expanded.map(\.id)).count == expanded.count, "item identities are scoped to their owning group")
        check(expanded.filter(\.endsGroup).count == groups.count, "exactly one separator ends each group, including empty groups")
        check(collapsed.map(\.id) == expanded.compactMap { row in
            if case .group = row.content { return row.id }
            return nil
        }, "expansion preserves header identities")
        var renderedIDs: [UUID] = []
        for row in expanded {
            if case .item(let groupIndex, let itemIndex) = row.content {
                renderedIDs.append(groups[groupIndex].items[itemIndex].id)
            }
        }
        check(renderedIDs == [first.id, second.id, first.id], "row indices preserve scan order and original selection identities")
        let partiallyExpanded = SmartCleanDetailRow.rows(groups: groups, expanded: ["a"])
        check(partiallyExpanded.map(\.id) == expanded.filter {
            $0.id != .item("b", first.id)
        }.map(\.id), "collapsing another group preserves every surviving row identity")
        let reordered = SmartCleanDetailRow.rows(groups: Array(groups.reversed()), expanded: ["a", "b"])
        check(Set(reordered.map(\.id)) == Set(expanded.map(\.id)), "group ordering cannot recreate row identities")
        let many = (0..<10_000).map { Node(name: String($0), size: 1) }
        let largeGroup = group("large", many)
        let largeRows = SmartCleanDetailRow.rows(groups: [largeGroup], expanded: [largeGroup.id])
        check(largeRows.count == many.count + 1 && Set(largeRows.map(\.id)).count == largeRows.count,
              "large expanded groups remain independent uniquely identified lazy rows")
        check(SmartCleanDetailRow.rows(groups: [largeGroup], expanded: []).count == 1,
              "collapsing a large group removes all folder rows")
        print("P9: \(passed) clean detail layout assertions passed")
    }
}
