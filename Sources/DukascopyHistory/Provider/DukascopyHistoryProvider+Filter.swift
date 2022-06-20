//
//  Created by Vitali Kurlovich on 14.06.22.
//

import DukascopyModel
import Foundation
import NIO

public
extension DukascopyHistoryProvider {
    func instrumentGroup(by id: String, caseInsensitive: Bool = true) -> EventLoopFuture<Group?> {
        firstInstrumentGroups { (caseInsensitive && id.caseInsensitiveCompare($0.id) == .orderedSame
        ) || (!caseInsensitive && id == $0.id)
        }
    }

    func firstInstrumentGroups(where isIncluded: @escaping (Group) throws -> Bool) -> EventLoopFuture<Group?> {
        func findGroup(from groups: [Group], isIncluded: @escaping (Group) throws -> Bool) rethrows -> Group? {
            for group in groups {
                if try isIncluded(group) {
                    return group
                } else if let find = try findGroup(from: group.groups, isIncluded: isIncluded) {
                    return find
                }
            }
            return nil
        }

        return allInstrumentGroups().flatMapThrowing { groups -> Group? in
            try findGroup(from: groups, isIncluded: isIncluded)
        }
    }
}

public
extension DukascopyHistoryProvider {
    func instrument(by symbol: String, caseInsensitive: Bool = true) -> EventLoopFuture<Instrument?> {
        firstInstrument {
            (caseInsensitive && symbol.caseInsensitiveCompare($0.symbol) == .orderedSame)
                || (!caseInsensitive && symbol == $0.symbol)
        }
    }

    func firstInstrument(where isIncluded: @escaping (Instrument) throws -> Bool) -> EventLoopFuture<Instrument?> {
        allInstruments().flatMapThrowing { instruments -> Instrument? in

            try instruments.first(where: isIncluded)
        }
    }
}
