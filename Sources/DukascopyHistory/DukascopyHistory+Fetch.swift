//
//  Created by Vitali Kurlovich on 29.05.22.
//

import Foundation

import DukascopyDecoder
import DukascopyModel
import NIO

public
extension DukascopyHistory {
    func fetchInstruments() -> EventLoopFuture<[Group]> {
        cache.groups().flatMapWithEventLoop { groups, eventLoop -> EventLoopFuture<[Group]> in
            if let groups = groups {
                return eventLoop.makeSucceededFuture(groups)
            }
            return self.fetchRemoteInstruments()
        }
    }
}

private
extension DukascopyHistory {
    func fetchRemoteInstruments() -> EventLoopFuture<[Group]> {
        let task = instrumentsTask()

        let result = task.result.flatMapThrowing { buffer -> [Group] in
            guard let buffer = buffer else {
                return []
            }

            let decoder = InstrumentsGroupsDecoder()

            return try decoder.decode(with: buffer)
        }.map { groups -> [Group] in

            let now = Date()
            self.cache.set(groups: groups, expireDate: now.addingTimeInterval(60 * 60))

            return groups
        }

        return result
    }
}

public
extension DukascopyHistory {
    func fetchQuoteTicks(for instrument: Instrument, date: Date) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        let filename = instrument.history.filename

        let task = task(format: .ticks, for: filename, date: date)

        return task.result.flatMapThrowing { (data: ByteBuffer?, _: String, period: Range<Date>) -> (instrument: Instrument, period: Range<Date>, ticks: [Tick]) in

            guard let buffer = data else {
                return (instrument: instrument, period: period, ticks: [])
            }

            let decoder = TicksDecoder()

            let ticks = try decoder.decode(with: buffer)

            return (instrument: instrument, period: period, ticks: ticks)
        }
    }

    func fetchQuoteTicks(for instrument: Instrument, range: Range<Date>) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        let filename = instrument.history.filename

        let tasks = tasks(format: .ticks, for: filename, range: range)

        let futures = tasks.map { task in

            task.result.flatMapThrowing { (data: ByteBuffer?, _: String, period: Range<Date>) -> (instrument: Instrument, period: Range<Date>, ticks: [Tick]) in

                guard let buffer = data else {
                    return (instrument: instrument, period: period, ticks: [])
                }

                let decoder = TicksDecoder()

                let ticks = try decoder.decode(with: buffer)

                return (instrument: instrument, period: period, ticks: ticks)
            }
        }

        return EventLoopFuture.whenAllComplete(futures, on: eventLoopGroup.next())
            .flatMapThrowing { results -> (instrument: Instrument, period: Range<Date>, ticks: [Tick]) in

                typealias QuoteItem = (instrument: Instrument, period: Range<Date>, ticks: [Tick])

                var items: [QuoteItem] = []

                items.reserveCapacity(results.underestimatedCount)

                for result in results {
                    switch result {
                    case let .failure(error):
                        throw error
                    case let .success(item):
                        items.append(item)

                        precondition(items.first!.instrument == item.instrument)
                    }
                }

                items.sort { left, right in
                    left.period.lowerBound < right.period.lowerBound
                }

                let instrument = items.first!.instrument
                let range = items.first!.period.lowerBound ..< items.last!.period.upperBound

                let ticks = items.flatMap { (_, period: Range<Date>, ticks: [Tick]) -> [Tick] in

                    let offset = Int32(period.lowerBound.timeIntervalSince(range.lowerBound)) * 1000

                    return ticks.lazy.map { tick in
                        Tick(time: tick.time + offset, askp: tick.askp, bidp: tick.bidp, askv: tick.askv, bidv: tick.bidv)
                    }
                }

                return (instrument: instrument, period: range, ticks: ticks)
            }
    }
}
