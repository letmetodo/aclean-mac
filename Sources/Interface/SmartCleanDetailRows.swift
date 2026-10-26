import Foundation

/// One identity per visible row lets the lazy stack virtualize expanded folders too.
struct SmartCleanDetailRow: Identifiable {
    enum ID: Hashable {
        case group(String)
        case item(String, UUID)
    }

    enum Content {
        case group(Int)
        case item(group: Int, item: Int)
    }

    let id: ID
    let content: Content
    let endsGroup: Bool

    static func rows(groups: [SmartAppCacheGroup], expanded: Set<String>) -> [Self] {
        var result: [Self] = []
        for (groupIndex, group) in groups.enumerated() {
            let showsItems = expanded.contains(group.id) && !group.items.isEmpty
            result.append(Self(id: .group(group.id), content: .group(groupIndex), endsGroup: !showsItems))
            if showsItems {
                for (itemIndex, item) in group.items.enumerated() {
                    result.append(Self(
                        id: .item(group.id, item.id),
                        content: .item(group: groupIndex, item: itemIndex),
                        endsGroup: itemIndex == group.items.count - 1
                    ))
                }
            }
        }
        return result
    }
}
