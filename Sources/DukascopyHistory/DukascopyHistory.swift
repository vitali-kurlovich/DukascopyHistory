//
//  Created by Vitali Kurlovich on 18.05.22.
//

import Foundation

import Logging
import NIO

public
final class DukascopyHistory {
    public enum EventLoopGroupProvider {
        /// `EventLoopGroup` will be provided by the user. Owner of this group is responsible for its lifecycle.
        case shared(EventLoopGroup)
        /// `EventLoopGroup` will be created by the client. When `syncShutdown` is called, created `EventLoopGroup` will be shut down as well.
        case createNew
    }

    internal
    init(_ client: HTTPRequestExecutorImpl, eventLoopGroupProvider: ClientEventLoopGroupProvider) {
        self.eventLoopGroupProvider = eventLoopGroupProvider

        requestExecutor = client

        cache = .init(eventLoopGroupProvider.eventLoopGroup)
    }

    internal let eventLoopGroupProvider: ClientEventLoopGroupProvider

    internal let requestExecutor: HTTPRequestExecutorImpl

    internal let cache: ClientCache
}

public
extension DukascopyHistory {
    convenience init(eventLoopGroupProvider: EventLoopGroupProvider,
                     backgroundActivityLogger: Logger)
    {
        let provider = ClientEventLoopGroupProvider(eventLoopGroupProvider)
        let imp = HTTPClientRequestExecutorImpl(eventLoopGroup: provider.eventLoopGroup, backgroundActivityLogger: backgroundActivityLogger)
        self.init(imp, eventLoopGroupProvider: provider)
    }

    convenience init(eventLoopGroupProvider: EventLoopGroupProvider) {
        let provider = ClientEventLoopGroupProvider(eventLoopGroupProvider)

        let imp = HTTPClientRequestExecutorImpl(eventLoopGroup: provider.eventLoopGroup)

        self.init(imp, eventLoopGroupProvider: provider)
    }

    var eventLoopGroup: EventLoopGroup {
        eventLoopGroupProvider.eventLoopGroup
    }
}
