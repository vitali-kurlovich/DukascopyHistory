//
//  Created by Vitali Kurlovich on 8.06.22.
//

import DukascopyModel
import Foundation
import NIO

public
extension DukascopyHistory {
    enum InstrumentError: Error {
        case doNotFindInstrumentBySymbol(symbol: String)
    }

    func fetchInstrument<S: StringProtocol>(by symbol: S, caseInsensitive: Bool = true) -> EventLoopFuture<Instrument> {
        let groups = fetchInstrumentGroups()

        return groups.flatMapThrowing { groups -> Instrument in

            let options: String.CompareOptions = caseInsensitive ? [.caseInsensitive] : []

            for group in groups {
                for instrument in group {
                    if instrument.symbol.compare(symbol, options: options) == .orderedSame {
                        return instrument
                    }
                }
            }

            throw InstrumentError.doNotFindInstrumentBySymbol(symbol: String(symbol))
        }
    }
}

public
extension DukascopyHistory {
    func fetchQuoteTicks<S: StringProtocol>(by symbol: S, caseInsensitive: Bool = true, date: Date) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        return fetchInstrument(by: symbol, caseInsensitive: caseInsensitive).flatMap { instrument in

            self.fetchQuoteTicks(for: instrument, date: date)
        }
    }

    func fetchQuoteTicks<S: StringProtocol>(by symbol: S, caseInsensitive: Bool = true, range: Range<Date>) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        return fetchInstrument(by: symbol, caseInsensitive: caseInsensitive).flatMap { instrument in

            self.fetchQuoteTicks(for: instrument, range: range)
        }
    }
}
