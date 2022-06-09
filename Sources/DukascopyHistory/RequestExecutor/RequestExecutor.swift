//
//  Created by Vitali Kurlovich on 9.06.22.
//

import Foundation
import NIO

protocol RequestExecutor {
    associatedtype Request
    associatedtype Response
    func execute(request: Request, deadline: NIODeadline?) -> EventLoopFuture<Response>
}

extension RequestExecutor {
    func execute(request: Request) -> EventLoopFuture<Response> {
        execute(request: request, deadline: nil)
    }
}

import AsyncHTTPClient

protocol HTTPRequestExecutor: RequestExecutor where Request == HTTPClient.Request, Response == HTTPClient.Response {}
