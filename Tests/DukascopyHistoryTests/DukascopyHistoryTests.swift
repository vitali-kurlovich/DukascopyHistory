//
//  DukascopyNIOClientTests.swift
//
//
//  Created by Vitali Kurlovich on 20.05.22.
//

import AsyncHTTPClient

@testable import DukascopyHistory
import DukascopyModel
import Logging
import NIO
import XCTest

enum TestError: Error {
    case doNotFindInstrument
}

class DukascopyHistoryTests: XCTestCase {
    func testDownloadData() throws {
        let expectation = XCTestExpectation(description: "Download Dukacopy bi5 file")

        let downloader = DukascopyHistory(eventLoopGroupProvider: .createNew)

        let date = formatter.date(from: "04-04-2019 11:00")!

        let task = downloader.task(format: .ticks, for: "EURUSD", date: date)

        XCTAssertEqual(task.period, date ..< formatter.date(from: "04-04-2019 12:00")!)

        task.result.whenSuccess { (data: ByteBuffer?, currency: String, period: Range<Date>) in
            XCTAssertNotNil(data)
            XCTAssertEqual(currency, "EURUSD")

            XCTAssertEqual(data?.readableBytes, 50435)

            XCTAssertEqual(period, task.period)

            expectation.fulfill()
        }

        task.result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testDownloadData_1() throws {
        let expectation = XCTestExpectation(description: "Download Dukacopy bi5 file")

        let downloader = DukascopyHistory(eventLoopGroupProvider: .createNew)

        let date = formatter.date(from: "06-01-2019 12:00")!

        let task = downloader.task(format: .ticks, for: "EURUSD", date: date)

        XCTAssertEqual(task.period, date ..< formatter.date(from: "06-01-2019 13:00")!)

        task.result.whenSuccess { (data: ByteBuffer?, currency: String, period: Range<Date>) in

            XCTAssertNil(data)
            XCTAssertEqual(currency, "EURUSD")
            XCTAssertEqual(period, task.period)

            expectation.fulfill()
        }

        task.result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testDownloadData_2() throws {
        let expectation = XCTestExpectation(description: "Download Dukacopy bi5 file")
        let logger = Logging.Logger(label: "Test Logger")

        let downloader = DukascopyHistory(eventLoopGroupProvider: .createNew, backgroundActivityLogger: logger)

        let begin = formatter.date(from: "04-04-2019 11:00")!
        let end = formatter.date(from: "04-04-2019 19:00")!

        let tasks = downloader.tasks(format: .ticks, for: "EURUSD", range: begin ..< end)

        XCTAssertEqual(tasks.count, 8)

        let results = tasks.map { task in
            task.result
        }

        let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let allTasks = EventLoopFuture.whenAllSucceed(results, on: eventGroup.any())

        allTasks.whenSuccess { result in
            result.forEach { (data: ByteBuffer?, currency: String, _: Range<Date>) in
                XCTAssertEqual(currency, "EURUSD")
                XCTAssertNotNil(data)
            }

            expectation.fulfill()
        }

        allTasks.whenFailure { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)

        try eventGroup.syncShutdownGracefully()
    }

    func testDownloadInstruments() throws {
        let downloader = DukascopyHistory(eventLoopGroupProvider: .createNew)

        var teskExp = XCTestExpectation(description: "Download instruments groups")

        let task = downloader.instrumentsTask()

        var resultBuffer: ByteBuffer?

        task.result.whenSuccess { buffer in
            XCTAssertNotNil(buffer)

            resultBuffer = buffer
            teskExp.fulfill()
        }

        task.result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [teskExp], timeout: 10.0)

        Thread.sleep(forTimeInterval: 2)

        teskExp = XCTestExpectation(description: "Download instruments groups using cache")

        let cacheTask = downloader.instrumentsTask()

        cacheTask.result.whenSuccess { buffer in
            XCTAssertNotNil(buffer)
            XCTAssertEqual(resultBuffer, buffer)
            teskExp.fulfill()
        }

        cacheTask.result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [teskExp], timeout: 10.0)
    }

    func testDownloadInstrumentGroups() throws {
        let expectation = XCTestExpectation(description: "Download instruments groups")

        let downloader = DukascopyHistory(eventLoopGroupProvider: .createNew)

        let result = downloader.fetchInstruments()

        result.whenSuccess { groups in
            XCTAssertFalse(groups.isEmpty)
            expectation.fulfill()
        }

        result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testDetchInstrument() throws {
        let downloader = DukascopyHistory(eventLoopGroupProvider: .createNew)

        let usdThbInstrument = downloader.fetchInstrument(by: "USD/THB", caseInsensitive: false)

        let expUSDTHB = XCTestExpectation(description: "Fetch USD/THB instrument")

        usdThbInstrument.whenSuccess { instrument in
            XCTAssertEqual(instrument.symbol, "USD/THB")
            expUSDTHB.fulfill()
        }

        usdThbInstrument.whenFailure { error in
            XCTFail(error.localizedDescription)
            expUSDTHB.fulfill()
        }

        wait(for: [expUSDTHB], timeout: 10.0)

        let expFail = XCTestExpectation(description: "Fetch non-existent instrument")
        let falilInstrument = downloader.fetchInstrument(by: "FailSymbol___$")

        falilInstrument.whenFailure { _ in
            expFail.fulfill()
        }

        wait(for: [expFail], timeout: 10.0)
    }

    func testFetchQuoteTicks() throws {
        let expectation = XCTestExpectation(description: "Fetch ticks")

        let downloader = DukascopyHistory(eventLoopGroupProvider: .createNew)

        let instrument = downloader.fetchInstrument(by: "USD/THB", caseInsensitive: false)

        let begin = formatter.date(from: "02-01-2020 01:00")!

        let result = instrument.flatMap { instrument in

            downloader.fetchQuoteTicks(for: instrument, date: begin)
        }

        result.whenSuccess { (instrument: Instrument, _: Range<Date>, ticks: [Tick]) in
            XCTAssertEqual(instrument.symbol, "USD/THB")

            XCTAssertEqual(ticks.count, 1096)

            // 02.01.2020 04:00:00.138 GMT+0300,30.1296,30.113400000000002,1,1
            let firstTick = ticks.first!
            XCTAssertEqual(firstTick.time, 138)
            XCTAssertEqual(firstTick.askp, 301_296)
            XCTAssertEqual(firstTick.bidp, 301_134)
            XCTAssertEqual(firstTick.askv, 1)
            XCTAssertEqual(firstTick.bidv, 1)

            // 02.01.2020 04:59:53.390 GMT+0300,30.1186,30.107400000000002,1.1,1.1
            let lastTick = ticks.last!

            XCTAssertEqual(lastTick.time, (59 * 60 + 53) * 1000 + 390)
            XCTAssertEqual(lastTick.askp, 301_186)
            XCTAssertEqual(lastTick.bidp, 301_074)
            XCTAssertEqual(lastTick.askv, 1.1)
            XCTAssertEqual(lastTick.bidv, 1.1)

            expectation.fulfill()
        }

        result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expectation], timeout: 10.0)

        let expSymbol = XCTestExpectation(description: "Fetch ticks by symbol")

        let result_1 = downloader.fetchQuoteTicks(by: "usd/thb", date: begin)

        result_1.whenSuccess { (instrument: Instrument, _: Range<Date>, ticks: [Tick]) in
            XCTAssertEqual(instrument.symbol, "USD/THB")

            XCTAssertEqual(ticks.count, 1096)

            // 02.01.2020 04:00:00.138 GMT+0300,30.1296,30.113400000000002,1,1
            let firstTick = ticks.first!
            XCTAssertEqual(firstTick.time, 138)
            XCTAssertEqual(firstTick.askp, 301_296)
            XCTAssertEqual(firstTick.bidp, 301_134)
            XCTAssertEqual(firstTick.askv, 1)
            XCTAssertEqual(firstTick.bidv, 1)

            // 02.01.2020 04:59:53.390 GMT+0300,30.1186,30.107400000000002,1.1,1.1
            let lastTick = ticks.last!

            XCTAssertEqual(lastTick.time, (59 * 60 + 53) * 1000 + 390)
            XCTAssertEqual(lastTick.askp, 301_186)
            XCTAssertEqual(lastTick.bidp, 301_074)
            XCTAssertEqual(lastTick.askv, 1.1)
            XCTAssertEqual(lastTick.bidv, 1.1)

            expSymbol.fulfill()
        }

        result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expSymbol], timeout: 10.0)
    }

    func testFetchQuoteTicks_1() throws {
        let expectation = XCTestExpectation(description: "Fetch ticks")

        let logger = Logger(label: "Test Logger for fitch ticks")

        let downloader = DukascopyHistory(eventLoopGroupProvider: .createNew, backgroundActivityLogger: logger)

        let instrument = downloader.fetchInstrument(by: "Usd/Thb")

        let begin = formatter.date(from: "02-01-2020 01:00")!
        let end = formatter.date(from: "02-01-2020 03:00")!

        let result = instrument.flatMap { instrument in

            downloader.fetchQuoteTicks(for: instrument, range: begin ..< end)
        }

        result.whenSuccess { (instrument: Instrument, _: Range<Date>, ticks: [Tick]) in
            XCTAssertEqual(instrument.symbol, "USD/THB")

            XCTAssertEqual(ticks.count, 1096 + 695)

            // 02.01.2020 04:00:00.138 GMT+0300,30.1296,30.113400000000002,1,1
            let firstTick = ticks.first!
            XCTAssertEqual(firstTick.time, 138)
            XCTAssertEqual(firstTick.askp, 301_296)
            XCTAssertEqual(firstTick.bidp, 301_134)
            XCTAssertEqual(firstTick.askv, 1)
            XCTAssertEqual(firstTick.bidv, 1)

            let lastTick = ticks.last!

            XCTAssertEqual(lastTick.time, (60 * 60) * 1000 + 3_599_269)
            XCTAssertEqual(lastTick.askp, 301_116)
            XCTAssertEqual(lastTick.bidp, 301_004)
            XCTAssertEqual(lastTick.askv, 1)
            XCTAssertEqual(lastTick.bidv, 1)

            expectation.fulfill()
        }

        result.whenFailure { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)

        let expSymbol = XCTestExpectation(description: "Fetch ticks by symbol")

        let result_1 = downloader.fetchQuoteTicks(by: "usd/thb", range: begin ..< end)

        result_1.whenSuccess { (instrument: Instrument, _: Range<Date>, ticks: [Tick]) in
            XCTAssertEqual(instrument.symbol, "USD/THB")

            XCTAssertEqual(ticks.count, 1096 + 695)

            // 02.01.2020 04:00:00.138 GMT+0300,30.1296,30.113400000000002,1,1
            let firstTick = ticks.first!
            XCTAssertEqual(firstTick.time, 138)
            XCTAssertEqual(firstTick.askp, 301_296)
            XCTAssertEqual(firstTick.bidp, 301_134)
            XCTAssertEqual(firstTick.askv, 1)
            XCTAssertEqual(firstTick.bidv, 1)

            let lastTick = ticks.last!

            XCTAssertEqual(lastTick.time, (60 * 60) * 1000 + 3_599_269)
            XCTAssertEqual(lastTick.askp, 301_116)
            XCTAssertEqual(lastTick.bidp, 301_004)
            XCTAssertEqual(lastTick.askv, 1)
            XCTAssertEqual(lastTick.bidv, 1)

            expSymbol.fulfill()
        }

        result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expSymbol], timeout: 10.0)
    }
}

private let utc = TimeZone(identifier: "UTC")!

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = utc
    return calendar
}()

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = utc
    formatter.dateFormat = "dd-MM-yyyy HH:mm"
    return formatter
}()
