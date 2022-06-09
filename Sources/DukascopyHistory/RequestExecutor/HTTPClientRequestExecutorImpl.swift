//
//  Created by Vitali Kurlovich on 9.06.22.
//

import AsyncHTTPClient
import Foundation
import Logging
import NIO

final class HTTPClientRequestExecutorImpl: HTTPRequestExecutorImpl {
    let client: HTTPClient

    init(eventLoopGroup: EventLoopGroup, backgroundActivityLogger: Logger) {
        client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup), backgroundActivityLogger: backgroundActivityLogger)
    }

    init(eventLoopGroup: EventLoopGroup) {
        client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
    }

    override func execute(request: HTTPClient.Request, deadline: NIODeadline?) -> EventLoopFuture<HTTPClient.Response> {
        client.execute(request: request, deadline: deadline)
    }

    deinit {
        try? client.syncShutdown()
    }
}
