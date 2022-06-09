//
//  Created by Vitali Kurlovich on 9.06.22.
//

import Foundation
import NIO
import NIOTransportServices

final class ClientEventLoopGroupProvider {
    public let eventLoopGroup: EventLoopGroup
    internal let eventLoopGroupProvider: DukascopyHistory.EventLoopGroupProvider

    init(_ eventLoopGroupProvider: DukascopyHistory.EventLoopGroupProvider) {
        self.eventLoopGroupProvider = eventLoopGroupProvider

        switch self.eventLoopGroupProvider {
        case let .shared(group):
            eventLoopGroup = group
        case .createNew:
            #if canImport(Network)
                if #available(OSX 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *) {
                    self.eventLoopGroup = NIOTSEventLoopGroup()
                } else {
                    eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
                }
            #else
                eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            #endif
        }
    }

    deinit {
        switch eventLoopGroupProvider {
        case .shared:
            break
        case .createNew:
            let queue: DispatchQueue = .global()
            self.eventLoopGroup.shutdownGracefully(queue: queue) { _ in
            }
        }
    }
}
