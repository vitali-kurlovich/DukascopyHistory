//
//  Created by Vitali Kurlovich on 16.06.22.
//

import DukascopyModel
import Foundation
import NIO

public
enum QuoteError: Error {
    case doNotFindInstrumentBySymbol(symbol: String)
}

public
extension DukascopyHistoryProvider {
    func quoteTicks(for instrument: Instrument, date: Date) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        history.fetchQuoteTicks(for: instrument, date: date)
    }

    func quoteTicks(for instrument: Instrument, range: Range<Date>) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        history.fetchQuoteTicks(for: instrument, range: range)
    }
}

public
extension DukascopyHistoryProvider {
    func quoteTicks(by symbol: String, caseInsensitive: Bool = true, date: Date) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        instrumentThrowing(by: symbol, caseInsensitive: caseInsensitive).flatMap {
            self.quoteTicks(for: $0, date: date)
        }
    }

    func quoteTicks(by symbol: String, caseInsensitive: Bool = true, range: Range<Date>) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        instrumentThrowing(by: symbol, caseInsensitive: caseInsensitive).flatMap {
            self.quoteTicks(for: $0, range: range)
        }
    }
}

public
extension DukascopyHistoryProvider {
    func instrumentThrowing(by symbol: String, caseInsensitive: Bool = true) -> EventLoopFuture<Instrument> {
        instrument(by: symbol, caseInsensitive: caseInsensitive).flatMapThrowing { instrument -> Instrument in

            guard let instrument = instrument else {
                throw QuoteError.doNotFindInstrumentBySymbol(symbol: symbol)
            }
            return instrument
        }
    }
}
