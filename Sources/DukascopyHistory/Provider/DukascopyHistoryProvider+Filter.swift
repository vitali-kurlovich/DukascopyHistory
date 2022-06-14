//
//  Created by Vitali Kurlovich on 14.06.22.
//

import DukascopyModel
import Foundation
import NIO

public
extension DukascopyHistoryProvider {
    func firstInstrumentGroups(by id: String, caseInsensitive: Bool = true) -> EventLoopFuture<Group?> {
        let id = caseInsensitive ? id.lowercased() : id

        return firstInstrumentGroups { $0.id == id || caseInsensitive && $0.id.lowercased() == id
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
    func firstInstrument(by symbol: String, caseInsensitive: Bool = true) -> EventLoopFuture<Instrument?> {
        let symbol = caseInsensitive ? symbol.lowercased() : symbol

        return firstInstrument { $0.symbol == symbol || caseInsensitive && $0.symbol.lowercased() == symbol
        }
    }

    func firstInstrument(where isIncluded: @escaping (Instrument) throws -> Bool) -> EventLoopFuture<Instrument?> {
        allInstruments().flatMapThrowing { instruments -> Instrument? in

            try instruments.first(where: isIncluded)
        }
    }
}
