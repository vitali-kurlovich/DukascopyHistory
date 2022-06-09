//
//  Created by Vitali Kurlovich on 9.06.22.
//

import Foundation

import AsyncHTTPClient
import NIO

class HTTPRequestExecutorImpl: HTTPRequestExecutor {
    func execute(request _: HTTPClient.Request, deadline _: NIODeadline?) -> EventLoopFuture<HTTPClient.Response> {
        fatalError("Must be implemented")
    }
}
