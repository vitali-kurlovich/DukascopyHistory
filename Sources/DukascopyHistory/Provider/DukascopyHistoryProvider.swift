//
//  Created by Vitali Kurlovich on 14.06.22.
//

import DukascopyModel
import Foundation
import NIO

public
struct DukascopyHistoryProvider {
    internal let history: DukascopyHistory

    public
    init(_ history: DukascopyHistory) {
        self.history = history
    }
}

public
extension DukascopyHistoryProvider {
    func allInstrumentGroups() -> EventLoopFuture<[Group]> {
        history.fetchInstrumentGroups()
    }

    func flatAllInstrumentGroups() -> EventLoopFuture<[Group]> {
        allInstrumentGroups().map { groups -> [Group] in
            groups.flatGroups()
        }
    }
}

public
extension DukascopyHistoryProvider {
    func allInstruments() -> EventLoopFuture<[Instrument]> {
        allInstrumentGroups().map { groups -> [Instrument] in
            groups.flatMap { $0 }
        }
    }
}

internal
extension Sequence where Self.Element == Group {
    func flatGroups() -> [Group] {
        var result: [Group] = []

        result.reserveCapacity(underestimatedCount)

        for group in self {
            _flatGroups(group: group, &result)
        }

        return result
    }

    private
    func _flatGroups(group: Group, _ dest: inout [Group]) {
        dest.append(Group(id: group.id, title: group.title, instruments: group.instruments, groups: []))

        dest.reserveCapacity(group.groups.underestimatedCount)

        for subgroup in group.groups {
            _flatGroups(group: subgroup, &dest)
        }
    }
}
