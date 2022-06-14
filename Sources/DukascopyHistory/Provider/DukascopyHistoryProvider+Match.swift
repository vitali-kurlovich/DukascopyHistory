//
//  Created by Vitali Kurlovich on 14.06.22.
//

import DukascopyModel
import Foundation
import NIO

public
extension DukascopyHistoryProvider {
    func matchInstrumentGroups(where isIncluded: @escaping (Group) throws -> Bool) -> EventLoopFuture<[Group]> {
        flatAllInstrumentGroups().flatMapThrowing { groups in
            try groups.filter(isIncluded)
        }
    }
}

public
extension DukascopyHistoryProvider {
    func matchInstruments(where isIncluded: @escaping (Instrument) throws -> Bool) -> EventLoopFuture<[Instrument]> {
        allInstruments().flatMapThrowing { instruments in
            try instruments.filter(isIncluded)
        }
    }
}
